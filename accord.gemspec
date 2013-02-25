# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "accord/version"

Gem::Specification.new do |s|
  s.name        = "accord"
  s.version     = Accord::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["rcabralc"]
  s.email       = ["rcabralc@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Contracts and adaptation for Ruby}
  s.description = %q{Contracts and adaptation for Ruby}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec')
end
