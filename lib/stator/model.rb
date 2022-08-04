# frozen_string_literal: true

module Stator
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :_stators
      attr_accessor :_stator_integrations

      validate :_stator_validate_transition

      self._stators ||= {}

      before_save :_stator_maybe_track_transition, prepend: true
    end

    class_methods do
      def stator(namespace: nil, field: :state, initial: nil, track: true, &block)

        unless initial.present? || abstract_class?
          # Discover the default value (usually initial) from the table...
          # but rescue nil since the table may not exist yet.
          initial = _determine_initial_stator_state_value(field)
        end

        opts = { namespace: _stator_namespace(namespace), field: field.to_sym, initial: initial, track: track }

        Stator::Machine.find_or_create(self, **opts).tap do |machine|
          machine.evaluate_dsl(&block) if block_given?
        end
      end

      def _stator(namespace)
        self._stators[_stator_namespace(namespace)]
      end

      def _stator_namespace(namespace = nil)
        namespace = nil if namespace.blank?

        (namespace || Stator.default_namespace).to_sym
      end

      def _determine_initial_stator_state_value(field)
        columns_hash[field.to_s].default.to_sym
      rescue StandardError
        nil
      end
    end

    def initialize_dup(other)
      @_stator_integrations = {}
      super
    end

    def without_state_transition_validations(namespace = '')
      _stator_integration(namespace).without_validation do
        yield self
      end
    end

    def without_state_transition_tracking(namespace = '')
      _stator_integration(namespace).without_transition_tracking do
        yield self
      end
    end

    def current_state
      _stator_integration.state&.to_sym
    end

    def in_state_at?(state, t, namespace = '')
      _stator_integration(namespace).in_state_at?(state, t)
    end

    def likely_state_at(t, namespace = '')
      _stator_integration(namespace).likely_state_at(t)
    end

    def state_by?(state, t, namespace = '')
      _stator_integration(namespace).state_by?(state, t)
    end

    private

    # core methods
    def _stator(namespace = nil)
      self.class._stator(namespace)
    end

    def _stator_namespace(namespace = nil)
      self.class._stator_namespace(namespace)
    end

    def _stator_integration(namespace = nil)
      ns = _stator_namespace(namespace)

      self._stator_integrations ||= {}
      self._stator_integrations[ns] ||= self.class._stator(ns).integration(self)
    end

    # validation/transitional
    def _stator_validate_transition
      self._stators.each_key do |namespace|
        _stator_integration(namespace).validate_transition
      end
    end

    def _stator_maybe_track_transition
      self._stators.each do |namespace, machine|
        next unless machine.tracking_enabled?

        _stator_integration(namespace).track_transition
      end

      true
    end
  end
end
