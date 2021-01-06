# frozen_string_literal: true

module Stator
  class Integration

    delegate :states,       to: :@machine
    delegate :transitions,  to: :@machine
    delegate :namespace,    to: :@machine

    def initialize(machine, record)
      @machine = machine
      @record  = record
    end

    def state=(new_value)
      @record.send("#{@machine.field}=", new_value)
    end

    def state
      @record.send(@machine.field)
    end

    def state_was(use_previous = false)
      if use_previous
        @record.previous_changes[@machine.field.to_s].try(:[], 0)
      else
        @record.attribute_in_database(@machine.field)
      end
    end

    def state_changed?(use_previous = false)
      if use_previous
        !!@record.previous_changes[@machine.field.to_s]
      else
        @record.will_save_change_to_attribute?(@machine.field)
      end
    end

    def validate_transition
      return unless state_changed?
      return if @machine.skip_validations

      was = state_was
      is  = state

      if @record.new_record?
        invalid_state! unless @machine.matching_transition(::Stator::Transition::ANY, is)
      else
        invalid_transition!(was, is) unless @machine.matching_transition(was, is)
      end
    end

    # TODO: i18n
    def invalid_state!
      @record.errors.add(@machine.field, "is not a valid state")
    end

    def invalid_transition!(was, is)
      @record.errors.add(@machine.field, "cannot transition to #{is.inspect} from #{was.inspect}")
    end

    def track_transition
      return if @machine.skip_transition_tracking

      attempt_to_track_state(state)
      attempt_to_track_state_changed_timestamp

      true
    end

    def in_state_at?(state, t)
      state = state.to_s
      t = t.to_time

      state_at = @record.send("#{state}_#{@machine.field}_at")

      # if we've never been in the state, the answer is no
      return false if state_at.nil?

      # if we came into this state later in life, the answer is no
      return false if state_at > t

      all_states = @machine.states.reverse

      # grab all the states and their timestamps that occur on or after state_at and on or before the time in question
      later_states = all_states.map do |s|
        next if state == s

        at = @record.send("#{s}_#{@machine.field}_at")

        next if at.nil?
        next if at < state_at
        next if at > t

        { state: s, at: at }
      end.compact

      # if there were no states on or after the state_at, the answer is yes
      return true if later_states.empty?

      # grab the states that were present at the lowest timestamp
      later_groups = later_states.group_by { |s| s[:at] }
      later_group_key = later_groups.keys.min
      later_states = later_groups[later_group_key]

      # if the lowest timestamp is the same as the state's timestamp, evaluate based on state index
      if later_states[0][:at] == state_at
        return all_states.index(state) < all_states.index(later_states[0][:state])
      end

      false
    end

    def likely_state_at(t)
      @machine.states.reverse.detect { |s| in_state_at?(s, t) }
    end

    protected

    def attempt_to_track_state(state_to_track)
      return unless state_to_track

      _attempt_to_track_change("#{state_to_track}_#{@machine.field}_at")
    end

    def attempt_to_track_state_changed_timestamp
      _attempt_to_track_change("#{@machine.field}_changed_at")
    end

    def _attempt_to_track_change(field_name)
      return unless @record.respond_to?(field_name)
      return unless @record.respond_to?("#{field_name}=")
      return unless @record.send(field_name.to_s).nil? || state_changed?
      return if @record.will_save_change_to_attribute?(field_name)

      @record.send("#{field_name}=", (Time.zone || Time).now)
    end

  end
end
