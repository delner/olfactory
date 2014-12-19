# Mock ORM module
module Saveable
  attr_accessor :saved
  def saved?
    !self.saved.nil? && self.saved
  end
  def save!
    self.saved = true
  end
end

class SaveableString < String
  include Saveable
end