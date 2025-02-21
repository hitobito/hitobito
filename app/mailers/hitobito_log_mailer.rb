# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class HitobitoLogMailer < ApplicationMailer
  ERROR = "hitobito_log_error"

  def error(error_log_entry_ids, time_period)
    @error_log_entry_ids = error_log_entry_ids
    @time_period = time_period

    custom_content_mail(recipients, ERROR, values_for_placeholders(ERROR))
  end

  private

  def placeholder_hitobito_log_url
    Rails.application.routes.url_helpers.hitobito_log_entries_url(
      host: ActionMailer::Base.default_url_options[:host]
    )
  end

  def placeholder_error_count
    error_log_entries.count
  end

  def placeholder_time_period
    formatted_time_period
  end

  def placeholder_error_log_table
    ApplicationController.render(
      partial: "hitobito_log_entries/email_error_table",
      layout: false,
      locals: {error_log_entries: error_log_entries.order(:created_at).limit(10)}
    ).html_safe
  end

  def formatted_time_period
    start_time = I18n.l(@time_period.begin)
    end_time = I18n.l(@time_period.end)
    "#{start_time} - #{end_time}"
  end

  def error_log_entries = HitobitoLogEntry.where(id: @error_log_entry_ids)

  def recipients = Settings.hitobito_log.recipient_emails
end
