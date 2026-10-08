# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ContactAccountAbility < AbilityDsl::Base
  MODELS = [AdditionalEmail, PhoneNumber, SocialAccount, AdditionalAddress].freeze

  MODELS.each do |model|
    on(model) do
      # Public contact accounts are listed for everybody, since there are no endpoints to list
      # all contactables.
      permission(:any).may(:index).public_or_of_contactables_with_details
    end
  end

  def public_or_of_contactables_with_details
    any_of({public: true},
      contactables(Person, accessible_ids(Person, :show_details)),
      contactables(Person, participation_details_people),
      contactables(Group, accessible_ids(Group, :show_details)))
  end

  private

  def participation_details_people
    context = user_context
    AbilityDsl::LazyRelation.new { context.participation_details_people.select(:id) }
  end

  def contactables(model_class, ids)
    {contactable_type: model_class.polymorphic_name, contactable_id: ids}
  end
end
