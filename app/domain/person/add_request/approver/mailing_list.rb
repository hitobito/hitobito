#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  class MailingList < Base
    private

    def build_entity
      request.body.subscriptions.where(subscriber: request.person).first_or_initialize.tap do |s|
        s.excluded = false
      end
    end
  end
end
