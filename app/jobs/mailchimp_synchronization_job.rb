# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpSynchronizationJob < BaseJob

  self.parameters = [:mailing_list_id]

  def initialize(mailing_list_id)
    super()
    @mailing_list_id = mailing_list_id
  end

  def enqueue(job)
    mailing_list.update(syncing_mailchimp: true)
  end

  def perform
    Synchronize::Mailchimp::Synchronizator.new(mailing_list).call
  end

  def success(job)
    mailing_list.update(syncing_mailchimp: false, last_synced_mailchimp_at: DateTime.now)
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
