$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'pry'
require 'spec/autorun'

require 'olfactory'

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

Spec::Runner.configure do |config|
  config.after do
    Olfactory.reload
  end
end