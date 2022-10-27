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
      { restrict_to_roles: role_sti_names,
        restrict_to_group_ids: group_ids }
    end

    private

    def role_sti_names
      sti_names = []
      group_subscriptions.each do |s|
        sti_names += s.role
      end
      sti_names
    end

    def group_ids
      group_subscriptions.pluck(:subscriber_id)
    end

    def group_subscriptions
      @group_subscriptions ||= @mailing_list.subscriptions.groups
    end

  end
end
