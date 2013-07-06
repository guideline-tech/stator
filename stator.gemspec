# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stator/version'

Gem::Specification.new do |gem|
  gem.name          = "stator"
  gem.version       = Stator::VERSION
  gem.authors       = ["Mike Nelson"]
  gem.email         = ["mike@mikeonrails.com"]
  gem.description   = %q{The simplest of ActiveRecord state machines. Intended to be lightweight and minimalistic.}
  gem.summary       = %q{The simplest of ActiveRecord state machines}
  gem.homepage      = "http://www.mikeonrails.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord'
end
