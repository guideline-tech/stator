module Stator
  class Transition

    ANY = '__any__'

    attr_reader :name
    attr_reader :full_name

    def initialize(class_name, name, namespace = nil)
      @class_name = class_name
      @name       = name
      @namespace  = namespace
      @full_name  = [@namespace, @name].compact.join('_') if @name
      @froms      = []
      @to         = nil
      @to_options = {}
      @callbacks  = {}
    end

    def from(*froms)
      @froms |= froms.map{|f| f.try(:to_s) } # nils are ok
    end

    def to(to, **options)
      @to = to.to_s
      @to_options = options
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

    def conditional(options = {}, &block)
      klass.instance_exec(conditional_block(options), &block)
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

    def conditional_block(options = {})
      options[:use_previous] ||= false

      _namespace = @namespace
      _froms     = @froms
      _to        = @to

      Proc.new do
        (
          self._stator(_namespace).integration(self).state_changed?(options[:use_previous])
        ) && (
          _froms.include?(self._stator(_namespace).integration(self).state_was(options[:use_previous])) ||
          _froms.include?(::Stator::Transition::ANY)
        ) && (
          self._stator(_namespace).integration(self).state == _to ||
          _to == ::Stator::Transition::ANY
        )
      end
    end

    def inferred_to_constant_name
      [@namespace, @to, klass._stator(@namespace).field].compact.join('_').upcase
    end

    def generate_methods
      if @to_options[:scope]
        name =
          if @to_options[:scope] == true
            [@namespace, @to].compact.join('_')
          else
            @to_options[:scope]
          end

        klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          scope #{name.inspect}, lambda {
            where(_stator(#{@namespace.inspect}).field => #{@to.inspect})
          }
        EV
      end

      if @to_options[:constant]
        name =
          if @to_options[:constant] == true
            inferred_to_constant_name
          else
            @to_options[:constant].to_s.upcase
          end

        klass.class_eval <<-EV, __FILE__, __LINE__ + 1
          #{name} = #{@to.inspect}.freeze
        EV
      end

      klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{@full_name}(should_save = true)
          integration = self._stator(#{@namespace.inspect}).integration(self)

          unless can_#{@full_name}?
            integration.invalid_transition!(integration.state, #{@to.inspect}) if should_save
            return false
          end

          integration.state = #{@to.inspect}
          self.save if should_save
        end

        def #{@full_name}!
          integration = self._stator(#{@namespace.inspect}).integration(self)

          unless can_#{@full_name}?
            integration.invalid_transition!(integration.state, #{@to.inspect})
            raise ActiveRecord::RecordInvalid.new(self)
          end

          integration.state = #{@to.inspect}
          self.save!
        end

        def can_#{@full_name}?
          machine     = self._stator(#{@namespace.inspect})
          return true if machine.skip_validations

          integration = machine.integration(self)
          transition  = machine.transitions.detect{|t| t.full_name.to_s == #{@full_name.inspect}.to_s }
          transition.can?(integration.state)
        end
      EV
    end

  end
end
