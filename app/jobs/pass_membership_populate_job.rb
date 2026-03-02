#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassMembershipPopulateJob < BaseJob
  self.parameters = [:pass_definition_id]

  def initialize(pass_definition_id)
    super()
    @pass_definition_id = pass_definition_id
  end

  def perform
    set_locale
    pass_definition = PassDefinition.find(@pass_definition_id)
    eligibility = Wallets::PassEligibility.new(pass_definition)

    eligibility.people.find_each do |person|
      pass = Pass.new(person: person, definition: pass_definition)

      membership = PassMembership.find_or_initialize_by(
        person: person,
        pass_definition: pass_definition
      )

      if pass.eligible?
        membership.update!(state: :eligible, valid_from: pass.valid_from, valid_until: pass.valid_until)
      elsif pass.has_ended?
        membership.update!(state: :ended, valid_from: pass.valid_from, valid_until: pass.valid_until)
      else
        membership.update!(state: :revoked)
      end
    end
  end
end
