# frozen_string_literal: true

#  Copyright (c) 2018-2020, Grünliberale Partei Schweiz. This file is part of
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
    return unless Settings.mailchimp.enabled

    sync.perform
  end

  def success(_job)
    mailing_list.update(mailchimp_syncing: false,
                        mailchimp_result: sync.result,
                        mailchimp_last_synced_at: Time.zone.now)
  end

  def error(job, exception)
    sync.result.exception = exception
    mailing_list.update(mailchimp_syncing: false,
                        mailchimp_result: sync.result)
    super
  end

  private

  def sync
    @sync ||= Synchronize::Mailchimp::Synchronizator.new(mailing_list)
  end

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
