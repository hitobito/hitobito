# frozen_string_literal: true

#  Copyright (c) 2018-2023, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ReoccuringMailchimpSynchronizationJob < RecurringJob

  run_every 24.hours

  def perform_internal
    MailingList.mailchimp.where.not(mailchimp_syncing: true).find_each do |list|
      next if list.mailchimp_result&.state == :failed

      MailchimpSynchronizationJob.new(list.id).enqueue!
    end
  end

end
