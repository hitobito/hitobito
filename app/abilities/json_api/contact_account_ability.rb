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
      SocialAccount,
      AdditionalAddress
    ]

    def initialize(user)
      @user = user

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

    attr_reader :user

    def readable_people
      Person.accessible_by(PersonReadables.new(user))
        .unscope(:select)
    end

    def details_readable_people
      Person.accessible_by(PersonDetailsReadables.new(user))
        .unscope(:select)
    end

    def details_writable_people
      details_readable_people
        .accessible_by(PersonWritables.new(user))
        .unscope(:select)
    end

    def readable_groups
      Group.accessible_by(GroupReadables.new(user))
    end

    def details_readable_groups
      Group.accessible_by(GroupDetailsReadables.new(user))
    end
  end
end
