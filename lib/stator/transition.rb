# frozen_string_literal: true

module Stator
  class Transition
    ANY = '__any__'.freeze

    attr_reader :name, :full_name

    def initialize(class_name, name, namespace = nil)
      @class_name = class_name
      @name       = name
      @namespace  = namespace
      @full_name  = [@namespace, @name].compact.join('_') if @name
      @froms      = []
      @to         = nil
      @callbacks  = {}
    end

    def from(*froms)
      @froms |= froms.map {|f| f.try(:to_s) } # nils are ok
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

    def conditional(options = {}, &block)
      klass.instance_exec(conditional_block(options), &block)
    end

    def any
      ANY
    end

    def evaluate
      generate_methods if @full_name.present?
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

      proc do
        (
          _stator(_namespace).integration(self).state_changed?(options[:use_previous])
        ) && (
          _froms.include?(_stator(_namespace).integration(self).state_was(options[:use_previous])) ||
          _froms.include?(::Stator::Transition::ANY)
        ) && (
          _stator(_namespace).integration(self).state == _to ||
          _to == ::Stator::Transition::ANY
        )
      end
    end

    def generate_methods
      klass.class_eval <<-EV, __FILE__, __LINE__ + 1
        def #{@full_name}(should_save = true)
          integration = _integration(#{@namespace.to_s.inspect})

          unless can_#{@full_name}?
            integration.invalid_transition!(integration.state, #{@to.inspect}) if should_save
            return false
          end

          integration.state = #{@to.inspect}
          self.save if should_save
        end

        def #{@full_name}!
          integration = _integration(#{@namespace.to_s.inspect})

          unless can_#{@full_name}?
            integration.invalid_transition!(integration.state, #{@to.inspect})
            raise ActiveRecord::RecordInvalid.new(self)
          end

          integration.state = #{@to.inspect}
          self.save!
        end

        def can_#{@full_name}?
          integration = _integration(#{@namespace.to_s.inspect})
          return true if integration.skip_validations

          machine     = self._stator(#{@namespace.to_s.inspect})
          transition  = machine.transitions.detect{|t| t.full_name.to_s == #{@full_name.inspect}.to_s }
          transition.can?(integration.state)
        end
      EV
    end
  end
end
