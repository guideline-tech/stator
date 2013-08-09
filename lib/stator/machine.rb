module Stator
  class Machine

    attr_reader :initial_state
    attr_reader :field
    attr_reader :transition_names
    attr_reader :transitions
    attr_reader :states
    attr_reader :namespace


    def initialize(klass, options = {})
      @class_name    = klass.name
      @field         = options[:field] || :state
      @namespace     = options[:namespace] || nil

      @initial_state = klass.columns_hash[@field.to_s].default

      @transitions      = []

      # pushed out into their own variables for performance reasons (AR integration can use method missing - see the HelperMethods module)
      @transition_names = []
      @states           = [@initial_state].compact

      @options       = options

    end

    def integration(record)
      ::Stator::Integration.new(self, record)
    end

    def get_transition(name)
      @transitions.detect{|t| t.name.to_s == name.to_s}
    end

    def transition(name, &block)
      
      t = ::Stator::Transition.new(@class_name, name, @namespace)
      t.instance_eval(&block) if block_given?

      verify_transition_validity(t)

      @transitions      << t
      @transition_names |= [t.full_name]  unless t.full_name.blank?
      @states           |= [t.to_state]   unless t.to_state.nil?

      t
    end

    def state(name, &block)
      transition(nil) do 
        from any
        to name
        instance_eval(&block) if block_given?
      end
    end

    def conditional(*states, &block)
      klass.instance_exec("#{states.map(&:to_s).inspect}.include?(self._stator(#{@namespace.inspect}).integration(self).state)", &block)
    end

    def matching_transition(from, to)
      @transitions.detect do |transition|
        transition.valid?(from, to)
      end
    end

    def evaluate
      @transitions.each(&:evaluate)
      generate_methods
    end

    protected

    def klass
      @class_name.constantize
    end

    def verify_transition_validity(transition)
      verify_state_singularity_of_transition(transition)
      verify_name_singularity_of_transition(transition)
    end

    def verify_state_singularity_of_transition(transition)
      transition.from_states.each do |from|
        if other = matching_transition(from, transition.to_state)
          raise "[Stator] another transition already exists which moves #{@class_name} from #{from.inspect} to #{transition.to_state.inspect}"
        end
      end
    end

    def verify_name_singularity_of_transition(transition)
      if other = @transitions.detect{|other| transition.name && transition.name == other.name }
        raise "[Stator] another transition already exists with the name of #{transition.name.inspect} in the #{@class_name} class"
      end
    end

    def generate_methods
      self.states.each do |state|
        method_name = [@namespace, state].compact.join('_')
        klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          def #{method_name}?
            integration = self._stator(#{@namespace.inspect}).integration(self)
            integration.state == #{state.to_s.inspect}
          end
        EV
      end
    end


  end
end