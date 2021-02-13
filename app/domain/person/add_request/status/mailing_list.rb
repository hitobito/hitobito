#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Status
  class MailingList < Base
    def created?
      Subscription.where(mailing_list_id: body_id,
                         subscriber_id: person_id,
                         subscriber_type: Person.name,
                         excluded: false)
        .exists?
    end
  end
end
