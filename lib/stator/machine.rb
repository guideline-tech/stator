module Stator
  class Machine

    attr_reader :initial_state
    attr_reader :field
    attr_reader :transition_names
    attr_reader :states


    def initialize(class_name, initial_state, options = {})
      @class_name    = class_name
      @initial_state = initial_state
      @field         = options[:field] || :state

      @transitions      = []

      # pushed out into their own variables for performance reasons (AR integration can use method missing - see the HelperMethods module)
      @transition_names = []
      @states           = []

      @options       = options

      # set up the nil-to-initial transition so validations can all work the same
      transition(nil) do
        from(nil)
        to(initial_state)
      end

    end

    def get_transition(name)
      @transitions.detect{|t| t.name.to_s == name.to_s}
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

      @transitions      << t
      @transition_names << t.name       unless t.name.nil?
      @states           << t.to_state   unless t.to_state.nil?

      t
    end

    def conditional(*states, &block)
      klass.instance_exec("#{states.map(&:to_s).inspect}.include?(self._stator_state)", &block)
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