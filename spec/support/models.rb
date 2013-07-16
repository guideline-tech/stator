class User < ActiveRecord::Base
  extend Stator::Model


  stator :pending do

    transition :activate do
      from :pending, :semiactivated
      to :activated
    end

    transition :deactivate do
      from any
      to :deactivated

      conditional do |condition|
        before_save :set_deactivated, :if => condition
      end
    end

    transition :semiactivate do
      from :pending
      to :semiactivated

      conditional do |condition|
        validate :check_email_validity, :if => condition
      end
    end

    transition :hyperactivate do
      from :activated
      to :hyperactivated
    end

    conditional :semiactivated, :activated do |condition|
      validate :check_email_presence, :if => condition
    end
  end

  validate :email_is_right_length

  protected

  def check_email_presence
    unless self.email.present?
      self.errors.add(:email, 'needs to be present')
      return false
    end

    true
  end

  def check_email_validity
    unless self.email.to_s =~ /example\.com$/
      self.errors.add(:email, 'format needs to be example.com')
      return false
    end

    true
  end

  def email_is_right_length
    unless self.email.to_s.length == 'four@example.com'.length
      self.errors.add(:email, 'needs to be the right length')
      return false
    end

    true
  end

  def set_deactivated
    self.activated = false
    true
  end

end

class Animal < ActiveRecord::Base
  extend Stator::Model

  stator :unborn, :field => :status, :helpers => true, :track => true do

    transition :birth do
      from :unborn
      to :born
    end

    state :grown_up

  end
end

class Zoo < ActiveRecord::Base
  extend Stator::Model

  stator :closed do

    transition :open do
      from :closed
      to :opened
    end

    transition :close do
      from  :opened
      to    :closed
    end

    conditional :opened do |c|
      validate :validate_lights_are_on, :if => c
    end
  end

  protected

  def validate_lights_are_on
    true
  end
end