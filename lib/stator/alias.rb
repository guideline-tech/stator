# frozen_string_literal: true

module Stator
  class Alias
    def initialize(machine, name, options = {})
      @machine    = machine
      @name       = name
      @namespace  = @machine.namespace
      @full_name  = [@namespace, @name].compact.join('_')
      @states     = []
      @not        = false
      @opposite   = nil
      @constant   = options[:constant]
      @scope      = options[:scope]
    end

    def is(*args)
      @states |= args.map(&:to_s)
    end

    def is_not(*args)
      @not = true
      is(*args)
    end

    def opposite(*args)
      @opposite = args
    end

    def evaluate
      generate_methods

      if @opposite
        op = @machine.state_alias(*@opposite)

        op.is(*@states)     if @not
        op.is_not(*@states) unless @not
      end
    end

    protected

    def inferred_constant_name
      [@full_name.upcase, @machine.field.to_s.pluralize.upcase].join('_')
    end

    def generate_methods
      not_states = (@machine.states - @states)

      if @scope
        name = @scope == true ? @full_name : @scope
        @machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          scope #{name.inspect}, lambda {
            where(_stator(#{@namespace.inspect}).field => #{(@not ? not_states : @states).inspect})
          }
        EV
      end

      if @constant
        name = @constant == true ? inferred_constant_name : @constant.to_s.upcase
        if @not
          @machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
            #{name} = #{not_states.inspect}.freeze
          EV
        else
          @machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
            #{name} = #{@states.inspect}.freeze
          EV
        end
      end

      @machine.klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{@full_name}?
          integration = _stator(#{@namespace.inspect}).integration(self)
          #{(@not ? not_states : @states).inspect}.include?(integration.state)
        end
      EV
    end
  end
end
