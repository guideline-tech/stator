# frozen_string_literal: true

require 'stator/version'
require 'stator/alias'
require 'stator/integration'
require 'stator/machine'
require 'stator/model'
require 'stator/transition'

require 'active_support/concern'
require 'debug'

module Stator
  ANY = :__ANY__

  def self.default_namespace
    ENV.fetch('STATOR_NAMESPACE', :default).to_sym
  end

  def self.satisfies_version?(vers)
    ::Gem::Requirement.new(vers).satisfied_by?(::ActiveRecord.gem_version)
  end
end
