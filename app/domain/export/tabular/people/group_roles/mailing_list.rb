# frozen_string_literal: true

#  Copyright (c) 2012-2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People::GroupRoles
  class MailingList

    def initialize(mailing_list)
      @mailing_list = mailing_list
    end

    def as_options
      { role_restrictions: role_restrictions }
    end

    private

    def role_restrictions
      group_subscriptions.each_with_object({}) do |s, restrictions|
        restrictions[s.subscriber_id] = s.role_types
      end
    end

    def group_subscriptions
      @group_subscriptions ||= @mailing_list.subscriptions.includes(:related_role_types).groups
    end

  end
end
