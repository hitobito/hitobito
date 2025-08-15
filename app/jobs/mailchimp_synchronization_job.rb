# frozen_string_literal: true

#  Copyright (c) 2018-2023, Grünliberale Partei Schweiz. This file is part of
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
    return unless FeatureGate.enabled?("mailchimp")

    sync.perform if mailing_list.mailchimp?
  end

  def success(_job)
    mailing_list.update(mailchimp_syncing: false,
      mailchimp_result: sync.result,
      mailchimp_last_synced_at: Time.zone.now)
  end

  def error(job, exception)
    sync.result.exception = exception
    mailing_list.update(mailchimp_syncing: false, mailchimp_result: sync.result)
    job.payload_object.create_log_entry
    super
  end

  def create_log_entry
    HitobitoLogEntry.create!(
      subject: mailing_list,
      level: :error,
      category: :mail,
      message: "Mailchimp Abgleich war nicht erfolgreich"
    )
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end

  def sync
    @sync ||= Synchronize::Mailchimp::Synchronizator.new(mailing_list)
  end
end
