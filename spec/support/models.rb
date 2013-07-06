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

      conditional do |c|
        c.before_save :set_deactivated
      end
    end

    transition :semiactivate do
      from :pending
      to :semiactivated

      conditional do |c|
        c.validate :check_email_validity
      end
    end

    transition :hyperactivate do
      from :activated
      to :hyperactivated
    end

    conditional :semiactivated, :activated do |c|
      c.validate :check_email_presence
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

  stator :unborn, :field => :status do

    transition :birth do
      from :unborn
      to :born
    end

  end
end