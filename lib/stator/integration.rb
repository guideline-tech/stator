module Stator
  class Integration

    delegate :states,       :to => :@machine
    delegate :transitions,  :to => :@machine
    delegate :namespace,    :to => :@machine

    def initialize(machine, record)
      @machine = machine
      @record  = record
    end




    def state=(new_value)
      @record.send("#{@machine.field}=",  new_value)
    end

    def state
      @record.send(@machine.field)
    end


    def state_was(use_previous = false)
      if use_previous
        @record.previous_changes[@machine.field.to_s].try(:[], 0)
      else
        @record.send("#{@machine.field}_was")
      end
    end


    def state_changed?(use_previous = false)
      if use_previous
        !!@record.previous_changes[@machine.field.to_s]
      else
        @record.send("#{@machine.field}_changed?")
      end
    end



    def validate_transition
      return unless self.state_changed?

      was = self.state_was
      is  = self.state

      if @record.new_record?
        invalid_state! unless @machine.matching_transition(::Stator::Transition::ANY, is)
      else
        invalid_transition!(was, is) unless @machine.matching_transition(was, is)
      end
    end

    # todo: i18n
    def invalid_state!
      @record.errors.add(@machine.field, "is not a valid state")
    end

    def invalid_transition!(was, is)
      @record.errors.add(@machine.field, "cannot transition to #{is.inspect} from #{was.inspect}")
    end

    def track_transition
      self.attempt_to_track_state(self.state_was)
      self.attempt_to_track_state(self.state)
      self.attempt_to_track_state_changed_timestamp

      true
    end


    protected

    def attempt_to_track_state(state_to_track)
      return unless state_to_track

      field_name = "#{state_to_track}_#{@machine.field}_at"

      return unless @record.respond_to?(field_name)
      return unless @record.respond_to?("#{field_name}=")

      unless @record.send(field_name)
        @record.send("#{field_name}=", (Time.zone || Time).now)
      end
    end

    def attempt_to_track_state_changed_timestamp
      return unless self.state_changed?

      field_name = "#{@machine.field}_changed_at"

      return unless @record.respond_to?(field_name)
      return unless @record.respond_to?("#{field_name}=")

      @record.send("#{field_name}=", (Time.zone || Time).now)
    end


  end
end
