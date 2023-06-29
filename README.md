# Stator

Stator is a minimalist's state machine. It's a simple dsl that uses existing ActiveRecord functionality to accomplish common state machine functionality. This is not a full-featured computer-science driven gem, it's a gem that covers the 98% of use cases that I've run into.

```ruby
gem 'stator', '~> x.y.z'
```

## Usage

If you've used the state_machine gem it's a pretty similar dsl. You define your state machine, transitions, states, and your callbacks (if any). One difference is that stator assumes you've set your db column's default value to the initial state.

```ruby
  class User < ActiveRecord::Base
    extend Stator::Model

    # initial state (column default) is "unactivated"
    stator do

      transition :semiactivate do
        from :unactivated
        to   :semiactivated
      end

      transition :activate do
        from :unactivated, :semiactivated
        to   :activated
      end

      transition :deactivate do
        from any
        to   :deactivate
      end

    end
  end
```

Then you use like this:

```ruby
u = User.new
u.state
# => 'unactivated'
u.persisted?
# => false
u.semiactivate
# => true
u.state
# => 'semiactivated'
u.persisted?
# => true
```

## Advanced Usage

The intention of stator was to avoid hijacking ActiveRecord or reinvent the wheel. You can conditionally validate, invoke callbacks, etc. via a conditional block - no magic:

```ruby
class User < ActiveRecord::Base
  extend Stator::Model

  stator field: :status, track: true do

    transition :activate do
      from :unactivated
      to   :activated

      # conditions is a string condition which will ensure the state
      # was one of the `from` states and is one of the `to` states.
      conditional do |conditions|
        validate :validate_user_ip_not_blacklisted, if: conditions
      end

    end

    # conditions is a string condition which will ensure the state
    # is one of the ones provided.
    conditional :unactivated do |conditions|
      validates :email, presence: true, unless: conditions
    end

  end
end
```

Within a transition, the `conditional` block accepts a `use_previous` option which tells the state checks to use the record's previous_changes rather than the current changes. This is especially useful for after_commit scenarios where the record's changes hash is cleared before the execution begins.

```ruby
transition :activate do
  from :unactivated
  to   :activated

  conditional(use_previous: true) do |conditions|
    after_commit :send_things, if: conditions
  end
```

The instance has some convenience methods which are generated by the state machine:

```ruby
u = User.new
u.activated?
# => false
u.can_activate?
# => true
```

Note that asking if a transition can take place via `can_[transition_name]?` does not invoke validations. It simply determines whether the record is in a state which the transition can take place from.

The `track: true` option enables timekeeping of the state transition. It will try to set a field in the format of "state_field_at" before saving the record. For example, in the previous state machine the following would occur:

```ruby
u = User.new
u.activate

u.activated_status_at
  # => (now)
```

`track: true` will also look for a "state_changed_at" field and will update that if it's present.

You can have multiple state machines for your model:

```ruby

class User < ActiveRecord::Base
  extend Stator::Model

  # initial state = asleep
  stator do
    # wake up
  end

  # initial state = incomplete
  stator namespace: 'homework', field: 'homework_state' do
    # get it done
  end
end
```

If you need to access the state machine directly, you can do so via the class:

```ruby
User._stator(namespace)
```

You can opt out of state transition validation by using the `without_state_transition_validations` method:

```ruby
user.without_state_transition_validations do
  user.activate!
end
```

#### Aliasing

It's a really common case to have a set of states evaluated as a single concept. For example, many apps have a concept of "active" users. You generally see something like this:

```ruby
class User < ActiveRecord::Base
  ACTIVE_STATES = %w(semiactivated activated)

  scope :active, -> { where(state: ACTIVE_STATES) }

  def active?
    self.state.in?(ACTIVE_STATES)
  end
end
```

To this point, we're doing ok. But how about defining inactive as well? At this point things start getting a little dirtier since a change to ACTIVE_STATES should impact INACTIVE_STATES. For this reason, stator allows you to define state aliases:

```ruby
class User < ActiveRecord::Base
  extend Stator::Model

  stator do
    # forgoing state definitions...

    state_alias :active do
      is :semiactivated, :activated
      opposite :inactive
    end
  end
end
```

The provided example will define an `active?` and `inactive?` method. If you want to create the constant and/or the scope, just pass them as options to the state_alias method:

```ruby
# will generate a User::ACTIVE_STATES constant, User.active scope, and User#active? instance method
state_alias :active, scope: true, constant: true do
  # ...
end
```

Passing `true` for the scope or constant will result in default naming conventions. You can pass your own names if you'd rather:

```ruby
# will generate a User::THE_ACTIVE_STATES constant, User.the_active_ones scope, and User#active? instance method
state_alias :active, scope: :the_active_ones, constant: :the_active_states do
  # ...
end
```

The `opposite` method also accepts the scope and constant options, but does not yield to a block since the state definitions are inheritenly tied to the ones described in the parent state_alias block.

## Development

Run test suite against current Rails version:

```
bundle exec rake spec
```

Run test suite against all supported Rails versions using `appraisal`:

```
bundle exec appraisal rake spec
```

For help updating the `Gemfile` or changing supported Rails versions, see the `appraisal` gem [README](https://github.com/thoughtbot/appraisal#usage).

Note that the gemfiles in `gemfiles/*` are auto-generated by `appraisal` and should not be modified directly.

#### TODO

- Allow for multiple variations of a transition (shift_down style - :third_gear => :second_gear, :second_gear => :first_gear)
- Create adapters for different backends (not just ActiveRecord)
