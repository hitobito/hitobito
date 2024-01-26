# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists
  class OptInCleanupJob < RecurringJob

    run_every 1.hour

    private

    def perform_internal
      lists.each do |list|
        Subscriptions::OptInCleanupJob.new(list.id).enqueue!
      end
    end

    def lists
      @lists ||= MailingList.opt_in.joins(:subscriptions).merge(Subscription.people)
    end
  end
end
