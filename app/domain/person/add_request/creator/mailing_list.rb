#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Creator
  class MailingList < Base
    alias subscription entity

    def required?
      subscription.subscriber.is_a?(Person) &&
        !subscription.excluded &&
        super()
    end

    def body
      subscription.mailing_list
    end

    def person
      subscription.subscriber
    end
  end
end
