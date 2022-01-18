# frozen_string_literal: true
#
#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Authenticatable::TwoFactor
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
  
  def prepare_registration!
    raise 'implement in subclass'
  end
  
  def reset!
    person.update!(encrypted_two_fa_secret: nil)
  end
  
  def disable!
    person.update!(encrypted_two_fa_secret: nil, two_factor_authentication: nil)
  end

  def prevent_brute_force!
    person.increment_failed_attempts
    if person.failed_attempts > Person.maximum_attempts
      person.lock_access! unless person.access_locked?
    end
  end

  def registered?
    raise 'implement in subclass'
  end
end
