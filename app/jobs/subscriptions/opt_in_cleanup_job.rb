# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriptions
  class OptInCleanupJob < BaseJob

    self.parameters = [:mailing_list_id]

    def initialize(mailing_list_id)
      super()
      @mailing_list_id = mailing_list_id
    end

    def perform
      allowed = MailingLists::Subscribers.new(list).allowed_to_opt_in.pluck(:id)
      subscribed = list.subscriptions.people.pluck(:subscriber_id)

      list.subscriptions.people.where(subscriber_id: subscribed - allowed).destroy_all
    end

    private

    def list
      @list ||= MailingList.find(@mailing_list_id)
    end
  end
end
