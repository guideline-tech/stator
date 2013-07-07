module Stator
  class Transition

    ANY = '__any__'

    attr_reader :name

    def initialize(class_name, name)
      @class_name = class_name
      @name       = name
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
      @froms.include?(current_state) || @froms.include?(ANY)
    end

    def valid?(from, to)
      can?(from) && 
      (@to == to || @to == ANY)
    end

    def conditional(&block)
      klass.with_options :if => conditional_string do |o|
        klass.instance_exec(o, &block)
      end
    end

    def any
      ANY
    end

    def evaluate
      generate_methods unless @name.nil?
    end

    protected

    def klass
      @class_name.constantize
    end

    def callbacks(kind)
      @callbacks[kind] || []
    end

    def conditional_string
      %Q{(#{@froms.inspect}.include?(self._stator_state_was) || #{@froms.inspect}.include?(::Stator::Transition::ANY)) && (self._stator_state == #{@to.inspect} || #{@to.inspect} == ::Stator::Transition::ANY)}
    end

    def generate_methods
      klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{@name}
          self._stator_state = #{@to.inspect}
          self.save
        end

        def #{@name}!
          self._stator_state = #{@to.inspect}
          self.save!
        end
      EV
    end

  end
end