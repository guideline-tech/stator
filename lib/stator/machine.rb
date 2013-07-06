require 'active_support/core_ext/object/with_options'

module Stator
  class Machine

    attr_reader :initial_state
    attr_reader :field


    def initialize(class_name, initial_state, options = {})
      @class_name    = class_name
      @initial_state = initial_state
      @field         = options[:field] || :state
      @transitions   = []
      @options       = options

      # set up the nil-to-initial transition so validations can all work the same
      transition(nil) do
        from(nil)
        to(initial_state)
      end

    end

    def states
      @transitions.map(&:to_state) - [::Stator::Transition::ANY]
    end

    def transition(name, &block)
      t = ::Stator::Transition.new(@class_name, name)
      t.instance_eval(&block) if block_given?

      t.from_states.each do |from|
        if other = matching_transition(from, t.to_state)
          raise "[Stator] another transition already exists which moves #{@class_name} from #{from.inspect} to #{t.to_state.inspect}"
        end
      end

      if other = @transitions.detect{|other| t.name == other.name }
        raise "[Stator] another transition already exists with the name of #{t.name.inspect} in the #{@class_name} class"
      end

      @transitions << t
      t
    end

    def conditional(*states, &block)
      condition = "#{states.map(&:to_s).inspect}.include?(self._stator_state)"

      klass.with_options :if => condition do |o|
        klass.instance_exec(o, &block)
      end
    end

    def matching_transition(from, to)
      @transitions.detect do |transition|
        transition.valid?(from, to)
      end
    end

    def evaluate
      @transitions.each(&:evaluate)
    end

    protected

    def klass
      @class_name.constantize
    end

  end
end