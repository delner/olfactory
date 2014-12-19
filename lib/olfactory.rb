# -*- encoding : utf-8 -*-
require 'olfactory/template_definition'
require 'olfactory/template'

module Olfactory
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
  def self.create_template(name, options = {}, &block)
    template = self.templates[name].build(block, options)
    template.save!
    template
  end

  def self.reload
    @@templates = {}
  end
end