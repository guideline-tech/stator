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
  gem.homepage      = "https://github.com/guideline-tech/stator"
  gem.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  gem.files = Dir["lib/**/*"] + Dir["*.gemspec"]

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.metadata["allowed_push_host"] = "https://rubygems.org"
  gem.metadata["rubygems_mfa_required"] = "true"

  gem.add_dependency 'base64'
  gem.add_dependency 'benchmark'
  gem.add_dependency 'bigdecimal'
  gem.add_dependency 'logger'
  gem.add_dependency 'mutex_m'
  gem.add_dependency 'activerecord', ">= 6.0"

  gem.required_ruby_version = ">= 3.2.0"
end
