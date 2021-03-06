# -*- encoding : utf-8 -*-
module Olfactory
  class Template < Hash
    attr_accessor :definition,
                  :transients,
                  :sequences,
                  :dictionaries,
                  :default_mode,
                  :default_populated,
                  :default_populated_transients,
                  :block_invocations

    def initialize(definition, options = {})
      self.definition = definition
      self.transients = options[:transients] ? options[:transients].clone : {}
      self.sequences = options[:sequences] ? options[:sequences].clone : {}
      self.dictionaries = options[:dictionaries] ? options[:dictionaries].clone : {}
      self.default_populated = {}
      self.default_populated_transients = {}
      self.block_invocations = []
    end

    def construct(block, options = {})
      self.add_defaults(:before) if options[:defaults].nil? || options[:defaults]
      if block # Block can be nil (when we want only defaults)
        if options[:value]
          block.call(self, options[:value])
        else
          block.call(self)
        end
      end
      self.add_defaults(:after) if options[:defaults].nil? || options[:defaults]
      self
    end
    def save!
      # Items, then subtemplates
      [self.definition.t_items, self.definition.t_subtemplates].each do |field_group_definitions|
        field_group_definitions.each do |field_name, field_definition|
          if field_value = self[field_name]
            if field_definition[:collection] && field_definition[:collection] <= Array
              field_value.each { |value| value.save! if value.respond_to?(:save!) }
            elsif field_definition[:collection] && field_definition[:collection] <= Hash
              field_value.values.each { |value| value.save! if value.respond_to?(:save!) }
            else
              field_value.save! if field_value.respond_to?(:save!)
            end
          end
        end
      end
    end

    def method_missing(meth, *args, &block)
      # Explicit fields
      if field_definition = self.definition.find_field_definition(meth)
        populate_field(field_definition, meth, args, block)
      else
        super # Unknown method
      end
    end
    def can_set_field?(name)
      !(self.default_mode && self.has_key?(name)) || (self.default_mode && (self.default_populated[name] == true))
    end
    def extract_variable_name(args)
      variable_name = args.first
      raise "Must provide a name when adding to a named field!" if variable_name.nil?
      variable_name
    end
    def populate_field(field_definition, meth, args, block)
      if field_definition[:type] == :macro
        field_value = construct_macro(field_definition, args, block)
        do_not_set_value = true
      elsif field_definition[:type] == :subtemplate && can_set_field?(field_definition[:name])
        subtemplate_name = field_definition.has_key?(:template) ? field_definition[:template] : field_definition[:name]
        subtemplate_definition = Olfactory.templates[subtemplate_name]
        subtemplate_definition ||= Olfactory.templates[field_definition[:singular]]
        if subtemplate_definition
          # Invoke before clauses
          self.add_defaults(:before_embedded)
          # self.default_mode = true
          # before_block = field_definition[:evaluator]
          # before_block.call(self) if before_block
          # self.default_mode = false

          if field_definition[:collection] && field_definition[:collection] <= Array
            # Embeds many
            if meth == field_definition[:singular]
              # Singular
              grammar = :singular
              preset_name = args.first

              field_value = construct_one_subtemplate(subtemplate_definition, preset_name, block)
            else
              # Plural
              grammar = :plural
              quantity = args.detect { |value| value.class <= Integer }
              preset_name = args.detect { |value| value != quantity }

              field_value = construct_many_subtemplates(subtemplate_definition, quantity, preset_name, block)
              do_not_set_value if field_value.nil?
            end
          elsif field_definition[:collection] && field_definition[:collection] <= Hash
            # Embeds many named
            if meth == field_definition[:singular]
              # Singular
              grammar = :singular
              variable_name = extract_variable_name(args)
              args = args[1..(args.size-1)]
              preset_name = args.first
              
              field_value = construct_one_subtemplate(subtemplate_definition, preset_name, block)
              do_not_set_value if field_value.nil? # || field_value.empty?
            else
              # Plural
              grammar = :plural
              do_not_set_value = true
              # UNSUPPORTED
            end
          else
            # Embeds one
            preset_name = args.first

            field_value = construct_one_subtemplate(subtemplate_definition, preset_name, block)
            do_not_set_value if field_value.nil?
          end

          # Invoke after clauses
          self.add_defaults(:after_embedded)
        else
          raise "Could not find a template matching '#{subtemplate_name}'!"
        end
      elsif field_definition[:type] == :item && can_set_field?(field_definition[:name])
        if field_definition[:collection] && field_definition[:collection] <= Array
          # Has many
          if meth == field_definition[:singular]
            # Singular
            grammar = :singular
            obj = args.count == 1 ? args.first : args
            
            field_value = construct_one_item(field_definition, obj, block)
            do_not_set_value = true if field_value.nil?
          else
            # Plural
            grammar = :plural
            quantity = args.first if block && args.first.class <= Integer
            arr = args.first if args.count == 1 && args.first.class <= Array

            field_value = construct_many_items(field_definition, quantity, arr, args, block)
            do_not_set_value = true if field_value.empty?
          end
        elsif field_definition[:collection] && field_definition[:collection] <= Hash
          # Has many named
          if meth == field_definition[:singular]
            # Singular
            grammar = :singular
            variable_name = extract_variable_name(args)
            args = args[1..(args.size-1)]
            obj = args.first

            field_value = construct_one_item(field_definition, obj, block)
            do_not_set_value = true if field_value.nil?
          else
            # Plural
            grammar = :plural
            hash = args.first if args.first.class <= Hash

            # Hash
            if hash
              field_value = hash
            end
            do_not_set_value = true if field_value.nil? || field_value.empty?
          end
        else
          # Has one
          obj = args.first
            
          field_value = construct_one_item(field_definition, obj, block)
        end
      elsif field_definition.class == Olfactory::Dictionary
        if field_definition.scope == :template
          return_value = field_definition
        elsif field_definition.scope == :instance
          return_value = (self.dictionaries[meth] ||= {})
        end
        do_not_set_value = true
      else
        do_not_set_value = true
      end

      # Add field value to template
      if !do_not_set_value
        if field_definition[:collection]
          self[field_definition[:name]] ||= field_definition[:collection].new
          if field_definition[:collection] <= Array
            if grammar == :plural
              return_value = self[field_definition[:name]].concat(field_value)
            elsif grammar == :singular
              return_value = self[field_definition[:name]] << field_value
            end
          elsif field_definition[:collection] <= Hash
            if grammar == :plural
              return_value = self[field_definition[:name]].merge!(field_value)
            elsif grammar == :singular
              return_value = self[field_definition[:name]][variable_name] = field_value
            end
          end
        else
          return_value = self[field_definition[:name]] = field_value
        end
        if self.default_mode && (self.default_populated[field_definition[:name]] != false)
          self.default_populated[field_definition[:name]] = true
        else
          self.default_populated[field_definition[:name]] = false
        end
      end
      return_value
    end
    def transient(name, value = nil, &block)
      if !(self.default_mode && self.transients.has_key?(name)) || (self.default_mode && (self.default_populated_transients[name] == true))
        self.transients[name] = (block ? block.call : value)
        if self.default_mode && (self.default_populated_transients[name] != false)
          self.default_populated_transients[name] = true
        else
          self.default_populated_transients[name] = false
        end
      end
    end
    def generate(name, options = {}, &block)
      sequence = self.definition.t_sequences[name]
      # Template scope
      if sequence && sequence[:scope] == :template
        value = sequence.generate(options, block)
      # Instance scope
      elsif sequence && sequence[:scope] == :instance
        self.sequences[name] ||= sequence.dup.reset
        value = self.sequences[name].generate(options, block)
        # self.sequences[name][:current_seed] += 1 if !options.has_key?(:seed)
      else
        raise "Unknown sequence '#{name}'!"
      end
      value
    end
    def build(name, *args)
      if instantiator_definition = self.definition.t_instantiators[name]
        instantiator_definition[:evaluator].call(self, *args)
      end
    end
    def create(name, *args)
      obj = self.build(name, *args)
      if obj.class <= Array
        obj.each { |o| o.save! if o.respond_to?(:save!) }
      elsif obj.class <= Hash
        obj.values.each { |o| o.save! if o.respond_to?(:save!) }
      elsif obj.respond_to?(:save!)
        obj.save!
      end
      obj
    end
    def add_defaults(mode)
      # Prevents overwrites of custom values by defaults
      self.default_mode = true # Hackish for sure, but its efficient...

      case mode
      when :before
        default_definitions = definition.t_befores[:all]
      when :after
        default_definitions = definition.t_afters[:all]
      when :before_embedded
        default_definitions = definition.t_befores[:embedded]
      when :after_embedded
        default_definitions = definition.t_afters[:embedded]
      end
      default_definitions ||= []
      default_definitions.reject! { |dfn| dfn[:run] == :once && self.block_invocations.include?(dfn.object_id) }
      
      default_definitions.each do |default_definition|
        if default_definition[:evaluator]
          default_definition[:evaluator].call(self)
        elsif default_definition[:preset]
          preset_definition = definition.find_preset_definition(default_definition[:preset])
          preset_definition[:evaluator].call(self)
        end
        self.block_invocations << default_definition.object_id if default_definition[:run] # Mark block as invoked
      end

      self.default_mode = false
    end
    def construct_macro(macro_definition, args, block)
      if macro_definition[:evaluator]
        macro_definition[:evaluator].call(self, *args)
      end
    end
    def construct_one_subtemplate(subtemplate_definition, preset_name, block)
      # Block
      if block
        subtemplate_definition.construct(block, :transients => self.transients)
      # Preset Name
      elsif preset_name
        subtemplate_definition.construct_preset(preset_name, 1, :transients => self.transients)
      # Default (nothing)
      else
        subtemplate_definition.construct(nil, :transients => self.transients)
      end
    end
    def construct_many_subtemplates(subtemplate_definition, quantity, preset_name, block)
      # Integer, Block
      if quantity && block
        Array.new(quantity) { subtemplate_definition.construct(block, :transients => self.transients) }
      # Integer, Preset Name
      elsif quantity && preset_name
        subtemplate_definition.construct_preset(preset_name, quantity, :transients => self.transients)
      # Integer
      elsif quantity
        Array.new(quantity) { subtemplate_definition.construct(nil, :transients => self.transients) }
      else
        nil
      end
    end
    def construct_one_item(item_definition, obj, block)
      if block
        block.call
      elsif obj
        obj
      else
        nil
      end
    end
    def construct_many_items(item_definition, quantity, arr, args, block)
      # Integer, Block
      if quantity && block
        Array.new(quantity) { block.call }
      # Array
      elsif arr
        arr
      # Object, Object...
      else
        args
      end
    end
    def reset_sequences(*names)
      names = self.sequences.keys if names.empty?
      names.each { |name| self.sequences[name].reset }
    end
    def reset_dictionaries(*names)
      names = self.dictionaries.keys if names.empty?
      names.each { |name| self.dictionaries[name].reset }
    end
  end
end