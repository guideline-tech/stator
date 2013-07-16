module Stator
  class Transition

    ANY = '__any__'

    attr_reader :name
    attr_reader :full_name

    def initialize(class_name, name, namespace = nil)
      @class_name = class_name
      @name       = name
      @namespace  = namespace
      @full_name  = [@namespace, @name].compact.join('_')
      @froms      = []
      @to         = nil
      @callbacks  = {}
    end

    def from(*froms)
      @froms |= froms.map{|f| f ? f.to_s : nil }
    end

    def to(to)
      @to = to.to_s
    end

    def to_state
      @to
    end

    def from_states
      @froms
    end

    def can?(current_state)
      @froms.include?(current_state) || @froms.include?(ANY) || current_state == ANY
    end

    def valid?(from, to)
      can?(from) && 
      (@to == to || @to == ANY || to == ANY)
    end

    def conditional(&block)
      klass.instance_exec(conditional_string, &block)
    end

    def any
      ANY
    end

    def evaluate
      generate_methods unless @full_name.blank?
    end

    protected

    def klass
      @class_name.constantize
    end

    def callbacks(kind)
      @callbacks[kind] || []
    end

    def conditional_string
      %Q{
          (
            #{@froms.inspect}.include?(self._stator(#{@namespace.inspect}).integration(self).state_was) || 
            #{@froms.inspect}.include?(::Stator::Transition::ANY)
          ) && (
            self._stator(#{@namespace.inspect}).integration(self).state == #{@to.inspect} || 
            #{@to.inspect} == ::Stator::Transition::ANY
          )
        }
    end

    def generate_methods
      klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{@full_name}(should_save = true)
          integration = self._stator(#{@namespace.inspect}).integration(self)
          integration.state = #{@to.inspect}
          self.save if should_save
        end

        def #{@full_name}!
          integration = self._stator(#{@namespace.inspect}).integration(self)
          integration.state = #{@to.inspect}
          self.save!
        end

        def can_#{@full_name}?
          machine     = self._stator(#{@namespace.inspect})
          integration = machine.integration(self)
          transition  = machine.transitions.detect{|t| t.full_name.to_s == #{@full_name.inspect}.to_s }
          transition.can?(integration.state)
        end
      EV
    end

  end
end