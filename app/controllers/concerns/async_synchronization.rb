# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Concerns
  module AsyncSynchronization
    def with_async_synchronization_cookie(mailing_list_id)
      AsyncSynchronizationCookie.new(cookies).set(mailing_list_id)
      #TODO: Properly localize flash message's text
      flash[:notice] = translate(:mailchimp_synchronization_enqueued, email: current_person.email)
    end
  end
end
