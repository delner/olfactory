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
        else
          raise "Missing preset matching '#{preset_name}' for template!"
        end
      else quantity <= 0
        raise "Can't build 0 or less items!"
      end
    end

    def find_preset_definition(preset_name)
      preset_definition = self.t_presets[preset_name]
      if preset_definition.nil?
        # Try to find a regexp named preset that matches
        preset_name = self.t_presets.keys.detect { |p_name| p_name.class == Regexp && p_name.match(preset_name.to_s) }
        preset_definition = self.t_presets[preset_name] if preset_name
      end
      preset_definition
    end

    # Defines a value holding field
    def has_one(name, options = {}, &block)
      self.t_items[name] = { :evaluator => block }.merge(options)
    end
    def has_many(name, options = {}, &block)
      self.t_items[name] = { :evaluator => block, :collection => true }.merge(options)
    end

    # Defines a hash-holding field
    def embeds_one(name, options = {}, &block)
      self.t_subtemplates[name] = { :evaluator => block }.merge(options)
    end
    def embeds_many(name, options = {}, &block)
      self.t_subtemplates[name] = { :evaluator => block, :collection => true }.merge(options)
    end

    # Defines a macro
    def macro(name, options = {}, &block)
      self.t_macros[name] = { :evaluator => block }.merge(options)
    end

    # Defines a preset of values
    def preset(name, options = {}, &block)
      self.t_presets[name] = { :evaluator => block }.merge(options)
      self.t_presets[name] = self.t_presets[name].merge(:regexp => name) if name.class <= Regexp
    end

    # Defines defaults
    def before(options = {}, &block)
      self.t_before = { :evaluator => block }.merge(options)
      self.t_before = self.t_before.merge(:preset => options[:preset]) if options[:preset]
    end
    def after(options = {}, &block)
      self.t_after = { :evaluator => block }.merge(options)
      self.t_after = self.t_after.merge(:preset => options[:preset]) if options[:preset]
    end
  end
end