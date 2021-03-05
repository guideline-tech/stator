module Stator
  module Model

    def stator(options = {}, &block)

      class_attribute :_stators unless respond_to?(:_stators)

      include InstanceMethods   unless self.included_modules.include?(InstanceMethods)
      include TrackerMethods    if options[:track] == true

      self._stators ||= {}

      unless self.abstract_class?
        f = options[:field] || :state
        # rescue nil since the table may not exist yet.
        initial = self.columns_hash[f.to_s].default rescue nil
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
          before_save :_stator_maybe_track_transition, prepend: true
        end
      end

      def in_state_at?(state, t, namespace = '')
        _integration(namespace).in_state_at?(state, t)
      end

      def likely_state_at(t, namespace = '')
        _integration(namespace).likely_state_at(t)
      end

      protected

      def _stator_maybe_track_transition
        self._stators.each do |namespace, machine|
          next unless machine.tracking_enabled?

          _integration(namespace).track_transition
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

      def without_state_transition_validations(namespace = '')
        _integration(namespace).without_validation do
          yield self
        end
      end

      def without_state_transition_tracking(namespace = '')
        _integration(namespace).without_transition_tracking do
          yield self
        end
      end

      protected

      def _stator_validate_transition
        self._stators.each_key do |namespace|
          _integration(namespace).validate_transition
        end
      end

      def _stator(namespace = '')
        self.class._stator(namespace)
      end

      def _integration(namespace = '')
        @_integrations ||= {}
        @_integrations[namespace] ||= _stator(namespace).integration(self)
        @_integrations[namespace]
      end

      def _integrations
        @_integrations
      end

    end
  end
end
