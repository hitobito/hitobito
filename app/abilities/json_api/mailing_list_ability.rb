# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class MailingListAbility
    include CanCan::Ability

    def initialize(main_ability)
      can :read, MailingList, subscribable: true
      can :read, MailingList, readable_mailing_lists(main_ability)
    end

    private

    def readable_mailing_lists(main_ability)
      MailingList.accessible_by(MailingListReadables.new(main_ability.user))
        .unscope(:select)
    end

    def readable_groups(main_ability)
      layer_group_ids = read_layer_ids(main_ability)
      {layer_group_id: layer_group_ids, archived_at: nil}
    end

    def read_layer_ids(main_ability)
      case main_ability
      when TokenAbility then [main_ability.token.layer.id] if main_ability.token.mailing_lists?
      else main_ability.user_context.permission_layer_ids
      end
    end
  end
end
