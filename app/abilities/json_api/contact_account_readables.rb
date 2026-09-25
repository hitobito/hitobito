# frozen_string_literal: true

#  Copyright (c) 2023-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class ContactAccountReadables
    include CanCan::Ability

    delegate :participation_details_people, to: :user_context

    CONTACT_ACCOUNT_MODELS = [
      AdditionalEmail,
      PhoneNumber,
      SocialAccount,
      AdditionalAddress
    ]

    def initialize(user)
      @user = user

      # Allow access to all public contact accounts, since we don't have endpoints to list all
      can :read, CONTACT_ACCOUNT_MODELS, public: true
      # allow reading all contacts of people on which the user has :show_details permissions
      can :read, CONTACT_ACCOUNT_MODELS, contactable: details_readable_people
      # allow reading all contacts of people whose participation details are readable
      can :read, CONTACT_ACCOUNT_MODELS, contactable: participation_details_people
      # allow reading all contacts of groups on which the user has :show_details permissions
      can :read, CONTACT_ACCOUNT_MODELS, contactable: details_readable_groups
    end

    private

    attr_reader :user

    def user_context
      @user_context ||= AbilityDsl::UserContext.new(user)
    end

    def details_readable_people
      Person.accessible_by(PersonDetailsReadables.new(user))
        .unscope(:select)
    end

    def details_readable_groups
      Group.accessible_by(GroupDetailsReadables.new(user))
    end
  end
end
