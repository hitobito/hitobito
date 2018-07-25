# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpBatchSynchronizationJob < RecurringJob

  def perform
    mailing_lists.each do |mailing_list|
      MailchimpSynchronizationJob.new(mailing_list.id).enqueue!
    end
  end

  private

  def mailing_lists
    @mailing_lists ||= MailingList.where.not(mailchimp_api_key: '', mailchimp_list_id: '')
  end
end
