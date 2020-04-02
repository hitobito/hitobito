# encoding: utf-8

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ReoccuringMailchimpSynchronizationJob < RecurringJob

  run_every 24.hours

  def perform
    MailingList.mailchimp.where.not(mailchimp_syncing: true).find_each do |list|
      MailchimpSynchronizationJob.new(list.id).enqueue!
    end
  end
end

