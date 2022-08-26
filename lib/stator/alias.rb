# frozen_string_literal: true

module Stator
  class Alias
    attr_reader :machine, :name, :namespace, :attr_name, :states, :not, :opposite_args, :constant, :scope

    def initialize(machine, name, options = {})
      @machine    = machine
      @name       = name
      @namespace  = machine.namespace
      @states     = []
      @not        = false
      @opposite   = nil
      @constant   = options[:constant]
      @scope      = options[:scope]
    end

    def attr_name
      @attr_name ||= generate_attr_name
    end

    def is(*args)
      @states |= args.map(&:to_sym)
    end

    def is_not(*args)
      @not = true
      is(*args)
    end

    alias not? not

    def opposite(*args)
      # set the incoming args for opposite as opposite
      @opposite_args = args
    end

    def evaluate
      generate_methods

      return if opposite_args.blank?

      # this will generate the alias for the opposite
      op = machine.state_alias(*opposite_args)

      op.is(*states)     if not?
      op.is_not(*states) unless not?
    end

    private

    def inverse_states
      (machine.states - states).map(&:to_sym)
    end

    def inferred_constant_name
      [attr_name.upcase, machine.field.to_s.pluralize.upcase].join('_')
    end

    def generate_attr_name
      if namespace == Stator.default_namespace
        name
      else
        [namespace, name].compact.join('_').to_sym
      end
    end

    def generate_methods
      expected_states = (not? ? inverse_states : states)

      if scope
        name = (scope == true ? attr_name : scope)

        machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          scope :#{name}, -> { where(_stator(#{namespace.inspect}).field => #{expected_states}) }
        EV
      end

      # this constant is being written as strings because of loads of code :(
      if constant
        name = (constant == true ? inferred_constant_name : constant.to_s.upcase)

        if not?
          machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
            #{name} = #{inverse_states.map(&:to_s)}.freeze
          EV
        else
          machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
            #{name} = #{states.map(&:to_s)}.freeze
          EV
        end
      end

      machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{attr_name}?
          integration = _stator_integration(:#{namespace})

          #{expected_states}.include?(integration.state&.to_sym)
        end
      EV
    end
  end
end
