$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'typesetter/version'

Gem::Specification.new do |s|
  s.name        = 'typesetter'
  s.version     = Typesetter::VERSION
  s.summary     = "Typesetter is an extension for factory gems, which adds templates."
  s.description = "Typesetter is an extension for factory gems, which adds templates that allow for easy creation of groups of objects."
  s.authors     = ["David Elner"]
  s.email       = 'david@davidelner.com'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {spec,features,gemfiles}/*`.split("\n")
  s.homepage    = 'https://github.com/StreetEasy/typesetter'
  s.license     = 'MIT'

  s.require_paths = ['lib']
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")

  s.add_development_dependency("rspec",    "~> 1.3.2")
  s.add_development_dependency("pry")
end