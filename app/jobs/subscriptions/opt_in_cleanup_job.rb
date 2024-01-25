# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriptions
  class OptInCleanupJob < RecurringJob
    run_every 1.hour

    private

    def perform_internal
      lists.find_each do |list|
        allowed = MailingLists::Subscribers.new(list).allowed_to_opt_in.pluck(:id)
        subscribed = list.subscriptions.people.pluck(:subscriber_id)

        list.subscriptions.people.where(subscriber_id: subscribed - allowed).destroy_all
      end
    end

    def lists
      @lists ||= MailingList.opt_in.joins(:subscriptions).merge(Subscription.people)
    end
  end
end
