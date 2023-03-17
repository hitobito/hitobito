# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class ContactAbility
    include CanCan::Ability

    CONTACT_MODELS = [
      AdditionalEmail,
      PhoneNumber,
      SocialAccount
    ]

    def initialize(main_ability)
      @main_ability = main_ability

      # allow reading public contacts of people on which the user has :show permission
      can :read, CONTACT_MODELS,
          public: true,
          contactable: readable_people(main_ability)

      # allow reading all contacts of people on which the user has :show_details permissions
      can :read, CONTACT_MODELS,
          contactable: details_readable_people(main_ability)

      # TODO: implement rules for Group contactables (and any other existing contactable classes)
    end

    private

    def readable_people(main_ability)
      Person.accessible_by(PersonReadables.new(main_ability.user)).
        unscope(:select)
    end

    def details_readable_people(main_ability)
      Person.accessible_by(PersonDetailsReadables.new(main_ability.user)).
        unscope(:select)
    end
  end
end
