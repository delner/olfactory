# -*- encoding : utf-8 -*-
require 'olfactory/dictionary'
require 'olfactory/sequence'
require 'olfactory/template_definition'
require 'olfactory/template'

module Olfactory
  @@templates = {}
  @@sequences = {}
  @@dictionaries = {}

  # Getters
  def self.templates
    @@templates
  end
  def self.sequences
    @@sequences
  end
  def self.dictionaries
    @@dictionaries
  end

  # Definitions
  def self.template(name, &block)
    new_template_definition = Olfactory::TemplateDefinition.new
    block.call(new_template_definition)
    self.templates[name] = new_template_definition
  end
  def self.sequence(name, options = {}, &block)
    sequences[name] = Olfactory::Sequence.new(name, options, block)
  end
  def self.dictionary(name)
    dictionaries[name] = Olfactory::Dictionary.new(name)
  end

  # Invocations
  def self.build(name, options = {}, &block)
    self.templates[name].construct(block, options)
  end
  def self.create(name, options = {}, &block)
    template = self.templates[name].construct(block, options)
    template.save!
    template
  end
  def self.generate(name, options = {}, &block)
    if sequence = self.sequences[name]
      sequence.generate(options, block)
    else
      raise "Unknown sequence '#{name}'!"
    end
  end

  def self.clear
    @@templates = {}
    @@sequences = {}
    @@dictionaries = {}
  end
  def self.reset
    self.reset_sequences
    self.reset_dictionaries
    self.reset_template_sequences
    self.reset_template_dictionaries
  end
  def self.reset_sequences(*names)
    names = self.sequences.keys if names.empty?
    names.each do |name|
      self.sequences[name].reset
    end
  end
  def self.reset_template_sequences(template, *names)
    if template = self.templates[template]
      template.reset_sequences(*names)
    end
  end
  def self.reset_dictionaries(*names)
    names = self.dictionaries.keys if names.empty?
    names.each do |name|
      self.dictionaries[name].reset
    end
  end
  def self.reset_template_dictionaries(template, *names)
    if template = self.templates[template]
      template.reset_dictionaries(*names)
    end
  end
end