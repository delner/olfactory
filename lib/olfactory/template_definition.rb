# -*- encoding : utf-8 -*-
module Olfactory
  class TemplateDefinition
    attr_accessor :t_items, :t_subtemplates, :t_macros, :t_presets, :t_before, :t_after

    def initialize
      self.t_items = {}
      self.t_subtemplates = {}
      self.t_macros = {}
      self.t_presets = {}
      self.t_before = {}
      self.t_after = {}
    end

    def build(block, options = {})
      if options[:preset] || options[:quantity]
        self.build_preset(options[:preset], (options[:quantity] || 1), options.reject { |k,v| [:preset, :quantity].include?(k) })
      else
        new_template = Template.new(self, options)
        new_template.build(block, options)
      end
      new_template
    end
    def build_preset(preset_name, quantity, options = {})
      raise "Quantity must be an integer!" if !(quantity.class <= Integer)

      if quantity > 1
        # Build multiple
        if preset_name
          Array.new(quantity) { self.build_preset(preset_name, 1, options) }
        else
          Array.new(quantity) { self.build(nil, options) }
        end
      elsif quantity == 1
        if preset_definition = self.find_preset_definition(preset_name)
          # Build single
          new_template = Template.new(self, options)
          preset_block = preset_definition[:evaluator]
          if preset_definition[:regexp]
            new_template.build(preset_block, options.merge(:value => preset_name))
          else
            new_template.build(preset_block, options)
          end
        elsif preset_name.nil?
          self.build(nil, options)
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

    def find_preset_definition(name)
      preset_definition = self.find_definition_in_list(name, self.t_presets)
      if preset_definition.nil?
        # Try to find a regexp named preset that matches
        name = self.t_presets.keys.detect { |p_name| p_name.class == Regexp && p_name.match(name.to_s) }
        preset_definition = self.t_presets[name] if name
      end
      preset_definition
    end

    # Defines a value holding field
    def has_one(name, options = {}, &block)
      self.t_items[name] = {  :type => :item,
                              :name => name,
                              :evaluator => block
                            }.merge(options)
    end
    def has_many(name, options = {}, &block)
      self.has_one(name, options.merge(:collection => true), &block)
    end

    # Defines a hash-holding field
    def embeds_one(name, options = {}, &block)
      self.t_subtemplates[name] = { :type => :subtemplate,
                                    :name => name,
                                    :evaluator => block 
                                  }.merge(options)
    end
    def embeds_many(name, options = {}, &block)
      self.embeds_one(name, options.merge(:collection => true), &block)
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

    # Defines defaults
    def before(options = {}, &block)
      self.t_before = { :type => :default,
                        :evaluator => block
                      }.merge(options)
      self.t_before = self.t_before.merge(:preset => options[:preset]) if options[:preset]
    end
    def after(options = {}, &block)
      self.t_after = {  :type => :default,
                        :evaluator => block }.merge(options)
      self.t_after = self.t_after.merge(:preset => options[:preset]) if options[:preset]
    end
  end
end