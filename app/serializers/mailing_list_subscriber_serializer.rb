# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListSubscriberSerializer < ContactSerializer
  schema do
    map_properties :primary_group_id
    property :primary_group_name, item.primary_group.name
    property :list_emails, Person.mailing_emails_for(item, context[:mailing_list].labels)
  end
end
