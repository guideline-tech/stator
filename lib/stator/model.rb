module Stator
  module Model

    def self.extended(base)
      base.class_eval do
        class << self
          alias_method :state_machine, :stator
        end
      end
    end

    def stator(initial_state, options = {}, &block)
      include InstanceMethods

      self._stator = ::Stator::Machine.new(self.name, initial_state, options)
      
      if block_given?
        self._stator.instance_eval(&block)
        self._stator.evaluate
      end

      self._stator
    end

    module InstanceMethods

      def self.included(base)
        base.class_eval do
          cattr_accessor    :_stator
          after_initialize  :_stator_set_default_state
          validate          :_stator_validate_transition
        end
      end

      protected

      def _stator_set_default_state
        return if self._stator_state
        self._stator_state = self._stator.initial_state.to_s
        self.changed_attributes.delete(self._stator.field.to_s)
        true
      end

      def _stator_validate_transition
        return unless self._stator_state_changed?

        was = self._stator_state_was
        is  = self._stator_state

        unless _stator.matching_transition(was, is)
          self.errors.add(self._stator.field, "cannot transition to #{is.inspect} from #{was.inspect}")
        end

      end

      def _stator_state
        self.send(self._stator.field)
      end

      def _stator_state=(val)
        self.send("#{self._stator.field}=",  val)
      end

      def _stator_state_changed?
        self.send("#{self._stator.field}_changed?")
      end

      def _stator_state_was
        self.send("#{self._stator.field}_was")
      end

      def _stator
        self.class.stator
      end

    end
  end
end