# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class MailingList < Base
    self.parent_sheet = Sheet::Group

    tab 'global.tabs.info',
        :group_mailing_list_path,
        alt: [:edit_group_mailing_list_path],
        if: :show

    tab 'activerecord.models.message.other',
        :group_mailing_list_messages_path,
        if: :update
    tab 'activerecord.models.subscription.other',
        :group_mailing_list_subscriptions_path,
        if: :index_subscriptions,
        params: { returning: true }

  end
end
