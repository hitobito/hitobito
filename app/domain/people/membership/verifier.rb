# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::Verifier

  def self.enabled?
    new(nil).respond_to?(:member?)
  end

  def initialize(person)
    @person = person
  end

  #def member?
  # implement me in wagon
  #end

end
