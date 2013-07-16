# Stator

Stator is a minimalist's state machine. It's a simple dsl that uses existing ActiveRecord functionality to accomplish common state machine funcitonality. This is not a full-featured computer-science driven gem, it's a gem that covers the 98% of use cases.

```ruby
gem 'stator', github: 'mnelson/stator', tag: 'v0.0.1'
```

## Usage

If you've used the state_machine it's a pretty similar dsl. You define your state machine with it's initial state, you define your transitions, and you define your callbacks (if any).

```ruby
  class User < ActiveRecord::Base
    extend Stator::Model

    stator :unactivated do

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

  stator :unactivated, field: :status, helpers: true, track: true do

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
The `helpers: true` option was passed to the previous state machine. This enables some convenience methods:

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

If you need to access the state machine directly, you can do so via the class:

```ruby
User._stator
```

#### TODO

* Allow for multiple variations of a transition (shift_down style - :third_gear => :second_gear, :second_gear => :first_gear)
* Create adapters for different backends (not just ActiveRecord)