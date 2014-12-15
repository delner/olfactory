# -*- encoding : utf-8 -*-
module Typesetter
  class TemplateDefinition
    attr_accessor :t_items, :t_subtemplates, :t_macros, :t_presets, :t_default

    def initialize
      self.t_items = {}
      self.t_subtemplates = {}
      self.t_macros = {}
      self.t_presets = {}
      self.t_default = {}
    end

    def build(block, options = {})
      if options[:preset]
        self.build_preset(options[:preset], options.reject { |k,v| k == :preset })
      else
        new_template = Template.new(self, options)
        new_template.build(block, options)
      end
      new_template
    end
    def build_preset(preset_name, options = {})
      if preset_name.class <= Integer
        # Build multiple
        Array.new(preset_name) { self.build(nil, options) }
      elsif preset_definition = self.find_preset_definition(preset_name)
        # Build single
        new_template = Template.new(self, options)
        preset_block = preset_definition[:evaluator]
        if preset_definition[:preset_name].class == Regexp
          new_template.build(preset_block, options.merge(:value => preset_name))
        else
          new_template.build(preset_block, options)
        end
      else
        raise "Missing preset matching '#{preset_value}' for template!"
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
    end

    # Defines defaults
    def default(preset_name = nil, options = {}, &block)
      self.t_default = { :preset_name => preset_name, :evaluator => block }.merge(options)
    end
  end
end