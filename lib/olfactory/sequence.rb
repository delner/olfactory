# -*- encoding : utf-8 -*-
module Olfactory
  class Sequence < Hash
    def initialize(name, options, block)
      self[:name] = name
      self[:evaluator] = block
      self[:scope] = (options[:scope] || :global)
      self[:seed] = (options[:seed] || 0)
      self[:dimensions] = { nil => { :current_seed => (options[:seed] || 0) } }
    end

    def generate(options = {}, block)
      seed = options[:seed] || (self[:dimensions][options[:dimension]] ||= { :current_seed => self[:seed] })[:current_seed]
      target = block || self[:evaluator]
      value = target.call(seed, options.reject { |k,v| [:seed, :dimension].include?(k) })
      self[:dimensions][options[:dimension]][:current_seed] += 1 if !options.has_key?(:seed)

      value
    end
    def reset
      self[:dimensions].values.each { |v| v[:current_seed] = self[:seed] }
      self
    end
  end
end