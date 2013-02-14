# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano-scrip/version"

Gem::Specification.new do |s|
  s.name        = "capistrano-scrip"
  s.version     = CapistranoScrip::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Vladimir Lyukov"]
  s.email       = %w(v.lyukov@gmail.com)
  s.homepage    = "https://github.com/glyuck/capistrano-scrip"
  s.summary     = "Bunch of capistrano recipes"
  s.description = "Some useful recipes for capistrano"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
  s.extra_rdoc_files = %w(LICENSE README.rdoc)

  s.add_dependency "capistrano", ">= 2.5.9"
  s.add_development_dependency "yard", "~> 0.8.4"
  s.add_development_dependency "redcarpet", "~> 2.2.2"
  s.add_development_dependency "rake", "~> 10.0.3"
end
