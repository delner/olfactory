module Olfactory
  class Dictionary < Hash
    attr_accessor :name, :scope

    def initialize(name, options = {})
      self.name = name
      self.scope = (options[:scope] || :global)
    end
    def reset
      self.clear
    end
  end
end