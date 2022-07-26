# frozen_string_literal: true

module Stator
  class Transition
    attr_reader :namespace, :name, :attr_name, :from_states, :to_state, :class_name, :callbacks

    def initialize(class_name, name, namespace = nil)
      @class_name  = class_name
      @name        = name&.to_sym
      @namespace   = namespace&.to_sym
      @from_states = []
      @to_state    = nil
      @callbacks   = {}
    end

    def attr_name
      @attr_name ||= generate_attr_name
    end

    def from_states(*new_froms)
      @from_states |= new_froms
    end
    alias from from_states

    def to(new_to)
      @to_state = new_to
    end

    def can?(current_state)
      from_states.include?(current_state) || from_states.include?(Stator::ANY) || current_state == Stator::ANY
    end

    def valid?(from_check, to_check)
      from_check = from_check&.to_sym # coming from the database, i suspect

      can?(from_check) && (to_check == to_state || to_check == ANY || to_state == ANY)
    end

    def conditional(options = {}, &block)
      klass.instance_exec(conditional_block(options), &block)
    end

    def any
      Stator::ANY
    end

    def evaluate
      generate_methods if attr_name.present?
    end

    private

    def klass
      class_name.constantize
    end

    def generate_attr_name
      if namespace == Stator.default_namespace
        name
      else
        [namespace, name].compact.join('_').to_sym
      end
    end

    def callbacks(kind)
      callbacks[kind] || []
    end

    def conditional_block(options = {})
      options[:use_previous] ||= false

      _namespace = namespace
      _froms     = from_states
      _to        = to_state

      proc do
        integration = self.class._stator(_namespace).integration(self)

        integration.state_changed?(options[:use_previous]) &&
          _froms.include?(integration.state_was(options[:use_previous])) ||
          _froms.include?(Stator::ANY) &&
            integration.state == _to || _to == Stator::ANY
      end
    end

    def generate_methods
      klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{attr_name}(should_save = true)
          integration = _stator_integration(:#{namespace})

          unless can_#{attr_name}?
            integration.invalid_transition!(integration.state, :#{to_state}) if should_save
            return false
          end

          integration.state = :#{to_state}

          self.save if should_save
        end

        def #{attr_name}!
          integration = _stator_integration(:#{namespace})

          unless can_#{attr_name}?
            integration.invalid_transition!(integration.state, :#{to_state})
            raise ActiveRecord::RecordInvalid.new(self)
          end

          integration.state = :#{to_state}
          self.save!
        end

        def can_#{attr_name}?
          integration = _stator_integration(:#{namespace})
          return true if integration.skip_validations

          machine     = self._stator(:#{namespace})
          transition  = machine.transitions.detect { |t| t.attr_name == :#{attr_name} }

          transition.can?(integration.state)
        end
      EV
    end
  end
end
