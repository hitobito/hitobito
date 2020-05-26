# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :name,
                   :description,
                   :publisher,
                   :mail_name,
                   :additional_sender,
                   :subscribable,
                   :subscribers_may_post,
                   :anyone_may_post,
                   :preferred_labels,
                   :delivery_report,
                   :main_email

    entity :group, item.group, GroupLinkSerializer
    entities :subscribers,
             item.people.includes(subscribers_includes),
             MailingListSubscriberSerializer
  end

  private

  def subscribers_includes
    [:primary_group]
  end
end
