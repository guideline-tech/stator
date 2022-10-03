# frozen_string_literal: true

module Stator
  class Machine
    attr_reader :initial_state, :field, :transitions, :states, :namespace,
                :class_name, :name, :aliases, :options, :tracking_enabled, :klass

    def self.find_or_create(klass, *kwargs)
      kwargs = kwargs.first

      klass._stators[kwargs[:namespace]] ||= new(klass, **kwargs)
    end

    def klass
      @klass ||= class_name.constantize
    end

    def initialize(klass, *options)
      options = options.first

      @class_name       = klass.name
      @field            = options[:field] || :state
      @namespace        = (options[:namespace] || Stator.default_namespace).to_sym

      @initial_state    = options[:initial]&.to_sym
      @states           = [initial_state].compact
      @tracking_enabled = options[:track] || false

      @transitions      = []
      @aliases          = []

      @options = options
    end

    alias tracking_enabled? tracking_enabled

    def evaluate_dsl(&block)
      instance_eval(&block)
      evaluate
    end

    def integration(record)
      Stator::Integration.new(self, record)
    end

    def transition(name, &block)
      Stator::Transition.new(class_name, name, namespace).tap do |t|
        t.instance_eval(&block) if block_given?

        verify_transition_validity(t)

        @transitions      << t
        @states           |= [t.to_state] unless t.to_state.nil?
      end
    end

    def state_alias(name, options = {}, &block)
      Stator::Alias.new(self, name, options).tap do |a|
        # puts "ALIAS: #{a.inspect}"
        a.instance_eval(&block) if block_given?
        @aliases << a
      end
    end

    def state(name, &block)
      transition(nil) do
        from any
        to name
        instance_eval(&block) if block_given?
      end
    end

    def conditional(*states, &block)
      state_check = proc { states.include?(current_state) }

      klass.instance_exec(state_check, &block)
    end

    def matching_transition(from, to)
      transitions.detect { |transition| transition.valid?(from, to) }
    end

    def evaluate
      transitions.each(&:evaluate)
      aliases.each(&:evaluate)
      generate_methods
    end

    private

    def attr_name(name)
      if namespace == Stator.default_namespace
        name.to_sym
      else
        [namespace, name].compact.join('_').to_sym
      end
    end

    def verify_transition_validity(transition)
      verify_state_singularity_of_transition(transition)
      verify_name_singularity_of_transition(transition)
    end

    def verify_state_singularity_of_transition(transition)
      transition.from_states.each do |from|
        if matching_transition(from, transition.to_state)
          raise "[Stator] another transition already exists which moves #{class_name} from #{from} to #{transition}"
        end
      end
    end

    def verify_name_singularity_of_transition(transition)
      if transitions.detect { |other| transition.name && transition.name == other.name }
        raise "[Stator] another transition already exists with the name of #{transition.name} in the #{class_name} class"
      end
    end

    def generate_methods
      states.each do |state|
        klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          def #{attr_name(state)}?
            _stator_integration(:#{namespace}).state.to_sym == :#{state}
          end

          def #{attr_name(state)}_state_by?(time)
            _stator_integration(:#{namespace}).state_by?(:#{state}.to_sym, time)
          end
        EV
      end
    end
  end
end
