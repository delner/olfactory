# -*- encoding : utf-8 -*-
module Olfactory
  class Template < Hash
    attr_accessor :definition, :transients, :sequences, :dictionaries, :default_mode

    def initialize(definition, options = {})
      self.definition = definition
      self.transients = options[:transients] ? options[:transients].clone : {}
      self.sequences = options[:sequences] ? options[:sequences].clone : {}
      self.dictionaries = options[:dictionaries] ? options[:dictionaries].clone : {}
    end

    def build(block, options = {})
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
    def can_set_field?(meth)
      !(self.default_mode && self.has_key?(meth))
    end
    def extract_variable_name(args)
      variable_name = args.first
      raise "Must provide a name when adding to a named field!" if variable_name.nil?
      variable_name
    end
    def populate_field(field_definition, meth, args, block)
      if field_definition[:type] == :macro
        field_value = build_macro(field_definition, args, block)
        do_not_set_value = true
      elsif field_definition[:type] == :subtemplate && can_set_field?(meth)
        subtemplate_name = field_definition.has_key?(:template) ? field_definition[:template] : field_definition[:name]
        subtemplate_definition = Olfactory.templates[subtemplate_name]
        subtemplate_definition ||= Olfactory.templates[field_definition[:singular]]
        if subtemplate_definition
          if field_definition[:collection] && field_definition[:collection] <= Array
            # Embeds many
            if meth == field_definition[:singular]
              # Singular
              grammar = :singular
              preset_name = args.first

              field_value = build_one_subtemplate(subtemplate_definition, preset_name, block)
            else
              # Plural
              grammar = :plural
              quantity = args.detect { |value| value.class <= Integer }
              preset_name = args.detect { |value| value != quantity }

              field_value = build_many_subtemplates(subtemplate_definition, quantity, preset_name, block)
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
              
              field_value = build_one_subtemplate(subtemplate_definition, preset_name, block)
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

            field_value = build_one_subtemplate(subtemplate_definition, preset_name, block)
            do_not_set_value if field_value.nil?
          end
        else
          raise "Could not find a template matching '#{subtemplate_name}'!"
        end
      elsif field_definition[:type] == :item && can_set_field?(meth)
        if field_definition[:collection] && field_definition[:collection] <= Array
          # Has many
          if meth == field_definition[:singular]
            # Singular
            grammar = :singular
            obj = args.count == 1 ? args.first : args
            
            field_value = build_one_item(field_definition, obj, block)
            do_not_set_value = true if field_value.nil?
          else
            # Plural
            grammar = :plural
            quantity = args.first if block && args.first.class <= Integer
            arr = args.first if args.count == 1 && args.first.class <= Array

            field_value = build_many_items(field_definition, quantity, arr, args, block)
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

            field_value = build_one_item(field_definition, obj, block)
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
            
          field_value = build_one_item(field_definition, obj, block)
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
      end
      return_value
    end
    def transient(name, value)
      self.transients[name] = value if !(self.default_mode && self.transients.has_key?(name))
    end
    def generate(name, options = {}, &block)
      sequence = self.definition.t_sequences[name]
      # Template scope
      if sequence && sequence[:scope] == :template
        value = sequence.generate(name, options, block)
      # Instance scope
      elsif sequence && sequence[:scope] == :instance
        self.sequences[name] ||= { :current_seed => (options[:seed] || sequence[:seed]) }
        value = sequence.generate(name, options.merge(:seed =>  self.sequences[name][:current_seed]), block)
        self.sequences[name][:current_seed] += 1 if !options.has_key?(:seed)
      else
        raise "Unknown sequence '#{name}'!"
      end
      value
    end
    def add_defaults(mode)
      # Prevents overwrites of custom values by defaults
      self.default_mode = true # Hackish for sure, but its efficient...

      case mode
      when :before
        default_definition = definition.t_before
      when :after
        default_definition = definition.t_after
      end
          
      if default_definition[:evaluator]
        default_definition[:evaluator].call(self)
      elsif default_definition[:preset]
        preset_definition = definition.find_preset_definition(default_definition[:preset])
        preset_definition[:evaluator].call(self)
      end

      self.default_mode = false
    end
    def build_macro(macro_definition, args, block)
      if macro_definition[:evaluator]
        macro_definition[:evaluator].call(self, *args)
      end
    end
    def build_one_subtemplate(subtemplate_definition, preset_name, block)
      # Block
      if block
        subtemplate_definition.build(block, :transients => self.transients)
      # Preset Name
      elsif preset_name
        subtemplate_definition.build_preset(preset_name, 1, :transients => self.transients)
      # Default (nothing)
      else
        subtemplate_definition.build(nil, :transients => self.transients)
      end
    end
    def build_many_subtemplates(subtemplate_definition, quantity, preset_name, block)
      # Integer, Block
      if quantity && block
        Array.new(quantity) { subtemplate_definition.build(block, :transients => self.transients) }
      # Integer, Preset Name
      elsif quantity && preset_name
        subtemplate_definition.build_preset(preset_name, quantity, :transients => self.transients)
      # Integer
      elsif quantity
        Array.new(quantity) { subtemplate_definition.build(nil, :transients => self.transients) }
      else
        nil
      end
    end
    def build_one_item(item_definition, obj, block)
      if block
        block.call
      elsif obj
        obj
      else
        nil
      end
    end
    def build_many_items(item_definition, quantity, arr, args, block)
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
  end
end