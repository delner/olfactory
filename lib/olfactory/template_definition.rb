# -*- encoding : utf-8 -*-
module Olfactory
  class TemplateDefinition
    attr_accessor :t_items, :t_subtemplates, :t_sequences, :t_dictionaries, :t_macros, :t_presets, :t_befores, :t_afters, :t_instantiators

    def initialize
      self.t_items = {}
      self.t_subtemplates = {}
      self.t_sequences = {}
      self.t_dictionaries = {}
      self.t_macros = {}
      self.t_presets = {}
      self.t_befores = {}
      self.t_afters = {}
      self.t_instantiators = {}
    end

    def construct(block, options = {})
      if options[:preset] || options[:quantity]
        self.construct_preset(options[:preset], (options[:quantity] || 1), options.reject { |k,v| [:preset, :quantity].include?(k) })
      else
        new_template = Template.new(self, options)
        new_template.construct(block, options)
      end
      new_template
    end
    def construct_preset(preset_name, quantity, options = {})
      raise "Quantity must be an integer!" if !(quantity.class <= Integer)

      if quantity > 1
        # Build multiple
        if preset_name
          Array.new(quantity) { self.construct_preset(preset_name, 1, options) }
        else
          Array.new(quantity) { self.construct(nil, options) }
        end
      elsif quantity == 1
        if preset_definition = self.find_preset_definition(preset_name)
          # Build single
          new_template = Template.new(self, options)
          preset_block = preset_definition[:evaluator]
          if preset_definition[:regexp]
            new_template.construct(preset_block, options.merge(:value => preset_name))
          else
            new_template.construct(preset_block, options)
          end
        elsif preset_name.nil?
          self.construct(nil, options)
        else
          raise "Missing preset matching '#{preset_name}' for template!"
        end
      else quantity <= 0
        raise "Can't build 0 or less items!"
      end
    end

    def find_field_definition(name)
      definition = find_macro_definition(name)
      definition ||= find_subtemplate_definition(name)
      definition ||= find_item_definition(name)
      definition ||= find_dictionary_definition(name)
      definition
    end

    def find_definition_in_list(name, definition_list)
      definition = definition_list[name]
      definition ||= definition_list.values.detect do |v|
        v.has_key?(:alias) && (v[:alias] == name || (v.respond_to?("include") && v.include?(name)))
      end
      definition
    end

    def find_macro_definition(name)
      self.find_definition_in_list(name, self.t_macros)
    end

    def find_subtemplate_definition(name)
      definition = self.find_definition_in_list(name, self.t_subtemplates)
      definition ||= self.t_subtemplates.values.detect { |v| v.has_key?(:singular) && v[:singular] == name }
      definition
    end

    def find_item_definition(name)
      definition = self.find_definition_in_list(name, self.t_items)
      definition ||= self.t_items.values.detect { |v| v.has_key?(:singular) && v[:singular] == name }
      definition
    end

    def find_dictionary_definition(name)
      self.t_dictionaries[name]
    end

    def find_preset_definition(name)
      preset_definition = self.find_definition_in_list(name, self.t_presets)
      if preset_definition.nil?
        # Try to find a regexp named preset that matches
        name = self.t_presets.keys.detect { |p_name| p_name.class == Regexp && p_name.match(name.to_s) }
        preset_definition = self.t_presets[name] if name
      end
      preset_definition
    end

    def reset_sequences(*names)
      names = self.t_sequences.keys if names.empty?
      names.each { |name| self.t_sequences[name].reset }
    end
    def reset_dictionaries(*names)
      names = self.t_dictionaries.keys if names.empty?
      names.each { |name| self.t_dictionaries[name].reset }
    end

    # Defines a value holding field
    def has_one(name, options = {}, &block)
      self.t_items[name] = {  :type => :item,
                              :name => name,
                              :evaluator => block
                            }.merge(options)
    end
    def has_many(name, options = {}, &block)
      self.has_one(name, options.merge(:collection => (options[:named] ? Hash : Array)), &block)
    end

    # Defines a hash-holding field
    def embeds_one(name, options = {}, &block)
      self.t_subtemplates[name] = { :type => :subtemplate,
                                    :name => name,
                                    :evaluator => block 
                                  }.merge(options)
    end
    def embeds_many(name, options = {}, &block)
      self.embeds_one(name, options.merge(:collection => (options[:named] ? Hash : Array)), &block)
    end

    # Defines a sequence
    def sequence(name, options = {}, &block)
      self.t_sequences[name] = Olfactory::Sequence.new(name, { :scope => :instance }.merge(options), block)
    end

    # Defines a dictionary
    def dictionary(name, options = {})
      self.t_dictionaries[name] = Olfactory::Dictionary.new(name, { :scope => :instance }.merge(options))
    end

    # Defines a macro
    def macro(name, options = {}, &block)
      self.t_macros[name] = { :type => :macro,
                              :name => name,
                              :evaluator => block 
                            }.merge(options)
    end

    # Defines a preset of values
    def preset(name, options = {}, &block)
      self.t_presets[name] = {  :type => :preset,
                                :name => name,
                                :evaluator => block
                              }.merge(options)
      self.t_presets[name] = self.t_presets[name].merge(:regexp => name) if name.class <= Regexp
    end

    # Defines an instantiator
    def instantiate(name, options = {}, &block)
      self.t_instantiators[name] = {  :type => :instantiator,
                                      :name => name,
                                      :evaluator => block 
                                    }.merge(options)
    end

    # Defines defaults
    def before(context = nil, options = {}, &block)
      if context.class == Hash
        # Arguments need to be remapped...
        options = context
        context = nil
      end
      before_definition = { :type => :default,
                            :evaluator => block
                          }.merge(options)
      before_definition.merge!(:preset => options[:preset]) if options[:preset]
      context ||= :all
      self.t_befores[context] ||= []
      self.t_befores[context] << before_definition
    end
    def after(context = nil, options = {}, &block)
      if context.class == Hash
        # Arguments need to be remapped...
        options = context
        context = nil
      end
      after_definition = { :type => :default,
                            :evaluator => block
                          }.merge(options)
      after_definition.merge!(:preset => options[:preset]) if options[:preset]
      context ||= :all
      self.t_afters[context] ||= []
      self.t_afters[context] << after_definition
    end
  end
end