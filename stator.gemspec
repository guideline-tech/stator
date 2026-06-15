# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "stator/version"

Gem::Specification.new do |spec|
  spec.name          = "stator"
  spec.version       = Stator::VERSION
  spec.authors       = ["Mike Nelson"]
  spec.email         = ["mike@mikeonrails.com"]
  spec.description   = "The simplest of ActiveRecord state machines. Intended to be lightweight and minimalistic."
  spec.summary       = "The simplest of ActiveRecord state machines"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  github_uri = "https://github.com/guideline-tech/stator"

  spec.homepage = github_uri
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = github_uri
  spec.metadata["changelog_uri"] = "#{github_uri}/releases"
  spec.metadata["github_repo"] = github_uri
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*"] + Dir["*.gemspec"]

  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "benchmark"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "logger"
  spec.add_dependency "mutex_m"
  spec.add_dependency "activerecord", ">= 8.0"
end
