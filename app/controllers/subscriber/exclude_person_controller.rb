# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class ExcludePersonController < PersonController

    skip_authorize_resource # must be in leaf class

    before_create :assert_subscribed

    private

    def assign_attributes
      super
      entry.excluded = true
    end

    def assert_subscribed
      if subscriber_id
        unless mailing_list.subscribed?(subscriber)
          entry.errors.add(:base, translate(:failure, subscriber: subscriber))
          false
        end
      end
    end

    def save_entry
      if subscriber_id
        @mailing_list.exclude_person(subscriber)
      else
        super
      end
    end

    def flash_message(state)
      if state == :success
        translate(:success, subscriber: subscriber)
      else
        super
      end
    end

  end
end
