# -*- encoding : utf-8 -*-
module Typesetter
  class Template < Hash
    attr_accessor :definition, :transients, :no_override

    def initialize(definition, options = {})
      self.definition = definition
      self.transients = options[:transients] ? options[:transients].clone : {}
    end

    def build(block, options = {})
      if block # Block can be nil (when we want only defaults)
        if options[:value]
          block.call(self, options[:value])
        else
          block.call(self)
        end
      end
      self.add_defaults
      self
    end

    def method_missing(meth, *args, &block)
      if !(self.has_key?(meth) && self.no_override) && \
          (definition.t_macros.has_key?(meth) || definition.t_subtemplates.has_key?(meth) || definition.t_items.has_key?(meth))
        # Explicit fields
        if definition.t_macros.has_key?(meth)
          field_type = :macro
          definition_of_field = definition.t_macros[meth]
          field_value = build_macro(definition_of_field, args, block)
        elsif definition.t_subtemplates.has_key?(meth)
          field_type = :subtemplate
          definition_of_field = definition.t_subtemplates[meth]
          subtemplate_name = definition_of_field.has_key?(:template) ? definition_of_field[:template] : meth
          field_value = build_subtemplate(Typesetter.templates[subtemplate_name], args, block)
        elsif definition.t_items.has_key?(meth)
          field_type = :item
          definition_of_field = definition.t_items[meth]
          field_value = build_item(definition_of_field, args, block)
        end

        # Add field value to template
        if definition_of_field[:collection]
          self[meth] = [] if !self.has_key?(meth)
          if field_type == :subtemplate && field_value.class <= Array
            self[meth].concat(field_value)
          else
            self[meth] << field_value
          end
        else
          self[meth] = field_value
        end
      # Non-explicit fields
      elsif args.count > 0 || block
        if block
          self[meth] = block.call
        else
          self[meth] = (args.count == 1 ? args.first : args)
        end
      else
        super # Unknown method
      end
    end

    def add_defaults
      self.no_override = true   # Kind of a hack, to prevent defaults from overriding values...
                                # More efficient than overriding pre-generated defaults, and allows for nicer syntax.
      default_definition = definition.t_default
      if default_definition[:evaluator]
        default_definition[:evaluator].call(self)
      elsif default_definition[:preset_name]
        preset_definition = definition.find_preset_definition(default_definition[:preset_name])
        preset_definition[:evaluator].call(self)
      end
      self.no_override = false
    end
    def build_macro(macro_definition, args, block)
      if macro_definition[:evaluator]
        macro_definition[:evaluator].call(*args)
      end
    end
    def build_subtemplate(subtemplate_definition, args, block)
      if block
        subtemplate_definition.build(block, :transients => self.transients)
      else
        subtemplate_definition.build_preset((args.count == 1 ? args.first : args), :transients => self.transients)
      end
    end
    def build_item(item_definition, args, block)
      if block
        block.call(*args) # Invoke block
      else
        if item_definition[:evaluator]
          item_definition[:evaluator].call(*args)
        else
          args.count == 1 ? args.first : argsnew
        end
      end
    end
  end
end