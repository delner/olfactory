# -*- encoding : utf-8 -*-
require 'typesetter/template_definition'
require 'typesetter/template'

module Typesetter
  @@templates = {}
  def self.templates
    @@templates
  end

  def self.template(name, &block)
    new_template_definition = TemplateDefinition.new
    block.call(new_template_definition)
    self.templates[name] = new_template_definition
  end

  def self.build_template(name, options = {}, &block)
    self.templates[name].build(block, options)
  end
end