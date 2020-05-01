# frozen_string_literal: true

module Stator
  module Model

    def stator(options = {}, &block)
      unless respond_to?(:_stators)
        class_attribute :_stators
        after_initialize :stator_ensure_initial_states
      end

      include InstanceMethods   unless included_modules.include?(InstanceMethods)
      include TrackerMethods    if options[:track] == true

      self._stators ||= {}

      unless abstract_class?
        f = options[:field] || :state
        # rescue nil since the table may not exist yet.
        initial = begin
                    columns_hash[f.to_s].default
                  rescue StandardError
                    nil
                  end
        options = options.merge(initial: initial) if initial
      end

      machine = (self._stators[options[:namespace].to_s] ||= ::Stator::Machine.new(self, options))

      if block_given?
        machine.instance_eval(&block)
        machine.evaluate
      end

      machine
    end

    def _stator(namespace)
      self._stators[namespace.to_s]
    end

    module TrackerMethods

      def self.included(base)
        base.class_eval do
          before_save :_stator_track_transition, prepend: true
        end
      end

      def in_state_at?(state, t, namespace = "")
        machine = _stator(namespace)
        machine.integration(self).in_state_at?(state, t)
      end

      def likely_state_at(t, namespace = "")
        machine = _stator(namespace)
        machine.integration(self).likely_state_at(t)
      end

      protected

      def _stator_track_transition
        self._stators.each do |_namespace, machine|
          machine.integration(self).track_transition
        end

        true
      end

    end

    module InstanceMethods

      def self.included(base)
        base.class_eval do
          validate :_stator_validate_transition
        end
      end

      def without_state_transition_validations(namespace = "")
        _stator(namespace).without_validation do
          yield
        end
      end

      def without_state_transition_tracking(namespace = "")
        _stator(namespace).without_transition_tracking do
          yield
        end
      end

      def stator_ensure_initial_states
        return if persisted?

        _stators.each_pair do |_namespace, machine|
          next unless machine.initial_state

          ix = machine.integration(self)
          ix.state = machine.initial_state if ix.state.nil?
        end
      end

      protected

      def _stator_validate_transition
        self._stators.each do |_namespace, machine|
          machine.integration(self).validate_transition
        end
      end

      def _stator(namespace = "")
        self.class._stator(namespace)
      end

    end

  end
end
