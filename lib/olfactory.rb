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
    new_template_definition = TemplateDefinition.new
    block.call(new_template_definition)
    self.templates[name] = new_template_definition
  end
  def self.sequence(name, options = {}, &block)
    sequences[name] = Sequence.new(name, options, block)
  end
  def self.dictionary(name)
    dictionaries[name] = Dictionary.new(name)
  end

  # Invocations
  def self.build_template(name, options = {}, &block)
    self.templates[name].build(block, options)
  end
  def self.create_template(name, options = {}, &block)
    template = self.templates[name].build(block, options)
    template.save!
    template
  end
  def self.generate(name, options = {}, &block)
    if sequence = self.sequences[name]
      sequence.generate(name, options, block)
    else
      raise "Unknown sequence '#{name}'!"
    end
  end

  def self.reload
    @@templates = {}
    @@sequences = {}
    @@dictionaries = {}
  end
  def self.reset_sequence(name)
    if sequence = self.sequences[name]
      sequence[:current_seed] = sequence[:seed]
    end
  end
  def self.reset_sequences(*names)
    names = self.sequences.keys if names.empty?
    names.each { |name| self.reset_sequence(name) }
  end
end