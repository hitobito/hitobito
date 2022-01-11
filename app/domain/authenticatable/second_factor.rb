class Authenticatable::SecondFactor
  attr_reader :person, :session

  def initialize(person, session)
    @person = person
    @session = session
  end

  def verify?(code)
    raise 'implement in subclass'
  end

  def register!
    raise 'implement in subclass'
  end
  
  def prepare_setup!
    raise 'implement in subclass'
  end
  
  def reset!
    person.update!(encrypted_totp_secret: nil)
  end
  
  def disable!
    person.update!(encrypted_totp_secret: nil, second_factor_auth: :no_second_factor)
  end

  def prevent_brute_force!
    person.increment_failed_attempts
    if person.failed_attempts > Person.maximum_attempts
      person.lock_access!
    end
  end

  def registered?
    raise 'implement in subclass'
  end
end
