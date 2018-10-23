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
        options = options.reverse_merge(initial: initial)
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
          before_validation :_stator_track_transition, prepend: true
        end
      end

      def in_state_at?(state, t, namespace = '')
        machine = self._stator(namespace)
        machine.integration(self).in_state_at?(state, t)
      end

      def likely_state_at(t, namespace = '')
        machine = self._stator(namespace)
        machine.integration(self).likely_state_at(t)
      end

      protected


      def _stator_track_transition

        self._stators.each do |namespace, machine|
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

      def without_state_transition_validations(namespace = '')
        self._stator(namespace).without_validation do
          yield
        end
      end

      def without_state_transition_tracking(namespace = '')
        self._stator(namespace).without_transition_tracking do
          yield
        end
      end

      protected

      def _stator_validate_transition
        self._stators.each do |namespace, machine|
          machine.integration(self).validate_transition
        end
      end

      def _stator(namespace = '')
        self.class._stator(namespace)
      end

    end
  end
end
