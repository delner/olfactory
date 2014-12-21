# -*- encoding : utf-8 -*-
module Olfactory
  class Sequence < Hash
    def initialize(name, options, block)
      self[:name] = name
      self[:evaluator] = block
      self[:scope] = (options[:scope] || :global)
      self[:seed] = (options[:seed] || 0)
      self[:current_seed] = (options[:seed] || 0)
    end

    def generate(name, options, block)
      seed = options[:seed] || self[:current_seed]
      target = block || self[:evaluator]
      value = target.call(seed, options.reject { |k,v| k == :seed })
      self[:current_seed] += 1 if !options.has_key?(:seed)

      value
    end
  end
end