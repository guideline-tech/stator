module Stator
  module Model

    def stator(initial_state, options = {}, &block)
      include InstanceMethods unless self.included_modules.include?(InstanceMethods)
      include TrackerMethods  if options[:track] == true

      machine = ::Stator::Machine.new(self.name, initial_state, options)

      self._stators ||= {}
      self._stators = self._stators.merge({machine.namespace.to_s => machine})
      
      if block_given?
        machine.instance_eval(&block)
        machine.evaluate
      end

      machine
    end

    module TrackerMethods

      def self.included(base)
        base.class_eval do
          before_save :_stator_track_transition
        end
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
          class_attribute   :_stators
          after_initialize  :_stator_set_default_state
          validate          :_stator_validate_transition
        end
      end

      protected

      def _stator_set_default_state
        self._stators.each do |namespace, machine|
          machine.integration(self).set_default_state
        end
      end

      def _stator_validate_transition
        self._stators.each do |namespace, machine|
          machine.integration(self).validate_transition
        end
      end

      def _stator(namespace)
        self._stators[namespace.to_s]
      end

    end
  end
end