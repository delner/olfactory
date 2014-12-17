# -*- encoding : utf-8 -*-
module Olfactory
  class Template < Hash
    attr_accessor :definition, :transients, :default_mode

    def initialize(definition, options = {})
      self.definition = definition
      self.transients = options[:transients] ? options[:transients].clone : {}
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
    def populate_field(field_definition, meth, args, block)
      if field_definition[:type] == :macro
        field_value = build_macro(field_definition, args, block)
      elsif field_definition[:type] == :subtemplate && can_set_field?(field_definition[:name])
        subtemplate_name = field_definition.has_key?(:template) ? field_definition[:template] : field_definition[:name]
        if subtemplate_definition = Olfactory.templates[subtemplate_name]
          field_value = build_subtemplate(subtemplate_definition, args, block)
        end
        field_value
      elsif field_definition[:type] == :item && can_set_field?(field_definition[:name])
        field_value = build_item(field_definition, args, block)
      else
        ignore = true
      end
      # Add field value to template
      if !ignore && field_definition[:type] && field_definition[:type] != :macro
        if field_definition[:collection]
          self[field_definition[:name]] ||= []
          if field_definition[:type] == :subtemplate && field_value.class <= Array
            self[field_definition[:name]].concat(field_value)
          else
            self[field_definition[:name]] << field_value
          end
        else
          self[field_definition[:name]] = field_value
        end
      end
    end
    def transient(name, value)
      self.transients[name] = value if !(self.default_mode && self.transients.has_key?(name))
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
    def build_subtemplate(subtemplate_definition, args, block)
      if block
        subtemplate_definition.build(block, :transients => self.transients)
      else
        preset_name = args.detect { |value| !(value.class <= Integer) }
        quantity = (args.detect { |value| value.class <= Integer } || 1)
        subtemplate_definition.build_preset(preset_name, quantity, :transients => self.transients)
      end
    end
    def build_item(item_definition, args, block)
      if block
        block.call(*args)
      else
        if item_definition[:evaluator]
          item_definition[:evaluator].call(*args)
        else
          args.count == 1 ? args.first : args
        end
      end
    end
  end
end