$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'olfactory/version'

Gem::Specification.new do |s|
  s.name        = 'olfactory'
  s.version     = Olfactory::VERSION
  s.summary     = "Olfactory is an extension for factory gems, which adds templates."
  s.description = "Olfactory is an extension for factory gems, which adds templates that allow for easy creation of groups of objects."
  s.authors     = ["David Elner"]
  s.email       = 'david@davidelner.com'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {spec,features,gemfiles}/*`.split("\n")
  s.homepage    = 'https://github.com/delner/olfactory'
  s.license     = 'MIT'

  s.require_paths = ['lib']
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")

  s.add_development_dependency("rspec", "~> 3.1")
  s.add_development_dependency("pry", "~> 0.10")
  s.add_development_dependency("pry-nav", "~> 0.2")
  s.add_development_dependency("pry-stack_explorer", "~> 0.4.9")
  s.add_development_dependency('rake', '~> 10.0.4')
  s.add_development_dependency('yard', '~> 0.8.7.6')
end