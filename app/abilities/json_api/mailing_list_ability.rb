# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class MailingListAbility
    include CanCan::Ability

    def initialize(main_ability)
      can :read, MailingList, readable_mailing_lists(main_ability)
    end

    private

    def readable_mailing_lists(main_ability)
      MailingList.accessible_by(MailingListReadables.new(main_ability.user))
        .unscope(:select)
    end
  end
end
