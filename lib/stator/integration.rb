# frozen_string_literal: true

module Stator
  class Integration
    delegate :states,       to: :machine
    delegate :transitions,  to: :machine
    delegate :namespace,    to: :machine

    attr_reader :skip_validations, :skip_transition_tracking, :record, :machine

    def initialize(machine, record)
      @skip_validations = false
      @machine = machine
      @record  = record
      @skip_transition_tracking = false
    end

    def state=(new_value)
      record.send("#{machine.field}=", new_value)
    end

    def state
      record.send(machine.field)&.to_sym
    end

    def state_was(use_previous = false)
      if use_previous
        record.previous_changes[machine.field].try(:[], 0).to_sym
      else
        if Stator.satisfies_version?("~> 5.1")
          record.attribute_in_database(machine.field)&.to_sym
        else
          record.send("#{machine.field}_was")&.to_sym
        end
      end
    end

    def can_move?(from_states, to_state, use_previous: false)
      (from_states.include?(state_was(use_previous)) || from_states.include?(Stator::ANY)) &&
        (state == to_state || to_state == Stator::ANY)
    end

    def state_by?(state, time)
      field_name = "#{state}_#{machine.field}_at"
      return false unless record.respond_to?(field_name)
      return false if record.send(field_name).nil?
      return true if time.nil?

      record.send(field_name) <= time
    end

    def state_changed?(use_previous = false)
      if use_previous
        !!record.previous_changes[machine.field.to_s]
      else
        if Stator.satisfies_version?("~> 5.1")
          record.will_save_change_to_attribute?(machine.field)
        else
          record.send("#{machine.field}_changed?")
        end
      end
    end

    def validate_transition
      return unless state_changed?
      return if skip_validations

      if record.new_record?
        invalid_state! unless machine.matching_transition(Stator::ANY, state)
      else
        invalid_transition!(state_was, state) unless machine.matching_transition(state_was, state)
      end

      return true
    end

    # TODO: i18n
    def invalid_state!
      record.errors.add(machine.field, 'is not a valid state')
    end

    def invalid_transition!(was, is)
      record.errors.add(machine.field, "cannot transition to #{is} from #{was}")
    end

    def track_transition
      return if skip_transition_tracking

      attempt_to_track_state(state)
      attempt_to_track_state_changed_timestamp

      true
    end

    def in_state_at?(state, timestamp)
      timestamp = timestamp.to_time

      state_at = record.send("#{state}_#{machine.field}_at")

      # if we've never been in the state, the answer is no
      return false if state_at.blank?

      # if we came into this state later in life, the answer is no
      return false if state_at > timestamp

      all_states = machine.states.reverse

      # grab all the states and their timestamps that occur on or after state_at and on or before the time in question
      later_states = all_states.filter_map do |s|
        next if state == s

        at = record.send("#{s}_#{machine.field}_at")

        next if at.nil? || at < state_at || at > timestamp

        { state: s, at: at }
      end

      # if there were no states on or after the state_at, the answer is yes
      return true if later_states.empty?

      # grab the states that were present at the lowest timestamp
      later_groups = later_states.group_by { |s| s[:at] }
      later_group_key = later_groups.keys.min
      later_states = later_groups[later_group_key]

      # if the lowest timestamp is the same as the state's timestamp, evaluate based on state index
      return all_states.index(state) < all_states.index(later_states[0][:state]) if later_states[0][:at] == state_at

      false
    end

    def likely_state_at(t)
      machine.states.reverse.detect { |s| in_state_at?(s, t) }
    end

    def without_validation
      was = skip_validations
      @skip_validations = true
      yield record
    ensure
      @skip_validations = was
    end

    def without_transition_tracking
      was = skip_transition_tracking
      @skip_transition_tracking = true
      yield record
    ensure
      @skip_transition_tracking = was
    end

    private

    def attempt_to_track_state(state_to_track)
      return unless state_to_track

      _attempt_to_track_change("#{state_to_track}_#{machine.field}_at")
    end

    def attempt_to_track_state_changed_timestamp
      _attempt_to_track_change("#{machine.field}_changed_at")
    end

    def _attempt_to_track_change(field_name)
      return unless record.respond_to?(field_name)
      return unless record.respond_to?("#{field_name}=")
      return unless record.send(field_name.to_s).nil? || state_changed?

      if Stator.satisfies_version?("~> 5.1")
        return if record.will_save_change_to_attribute?(field_name)
      else
        return if record.send("#{field_name}_changed?")
      end

      record.send("#{field_name}=", (Time.zone || Time).now)
    end
  end
end
