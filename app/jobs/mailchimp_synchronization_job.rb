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

  def enqueue(_job)
    mailing_list.update!(mailchimp_syncing: true)
  end

  def perform
    Synchronize::Mailchimp::Synchronizator.new(mailing_list).call
  end

  def success(_job)
    mailing_list.update!(mailchimp_syncing: false, mailchimp_last_synced_at: Time.zone.now)
  end

  def error(*args)
    mailing_list.update!(mailchimp_syncing: false)
    super
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
