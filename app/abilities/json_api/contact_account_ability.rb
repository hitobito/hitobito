# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class ContactAccountAbility
    include CanCan::Ability

    CONTACT_ACCOUNT_MODELS = [
      AdditionalEmail,
      PhoneNumber,
      SocialAccount
    ]

    attr_reader :main_ability

    def initialize(main_ability)
      @main_ability = main_ability

      # Person ContactAccounts
      # allow reading public contacts of people on which the user has :show permission
      can :read, CONTACT_ACCOUNT_MODELS,
        public: true, contactable: readable_people
      # allow reading all contacts of people on which the user has :show_details permissions
      can :read, CONTACT_ACCOUNT_MODELS, contactable: details_readable_people

      can :create, CONTACT_ACCOUNT_MODELS, contactable: details_writable_people

      can :update, CONTACT_ACCOUNT_MODELS, contactable: details_writable_people

      can :destroy, CONTACT_ACCOUNT_MODELS, contactable: details_writable_people

      # Group ContactAccounts
      can :read, CONTACT_ACCOUNT_MODELS, public: true, contactable: readable_groups

      can :read, CONTACT_ACCOUNT_MODELS, contactable: details_readable_groups
    end

    private

    def readable_people
      Person.accessible_by(PersonReadables.new(main_ability.user))
        .unscope(:select)
    end

    def details_readable_people
      Person.accessible_by(PersonDetailsReadables.new(main_ability.user))
        .unscope(:select)
    end

    def details_writable_people
      details_readable_people
        .accessible_by(PersonWritables.new(main_ability.user))
        .unscope(:select)
    end

    def readable_groups
      Group.accessible_by(GroupReadables.new(main_ability.user))
    end

    def details_readable_groups
      Group.accessible_by(GroupDetailsReadables.new(main_ability.user))
    end
  end
end
