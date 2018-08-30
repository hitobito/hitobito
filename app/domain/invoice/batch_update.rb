# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::BatchUpdate

  attr_reader :invoices, :sender

  def initialize(invoices, sender = nil)
    @invoices = invoices
    @sender = sender
  end

  def call # rubocop:disable Metrics/MethodLength
    invoices.each do |invoice|
      next_state = compute_next_state(invoice)
      next if invalid?(invoice, next_state)

      Invoice.transaction do
        if invoice.update(state: next_state)
          track_state_change(invoice, next_state)
          handle_email(invoice) if send_email?
          create_reminder(invoice) if invoice.overdue?
        else
          result.track_model_error(invoice)
        end
      end
    end

    result
  end

  private

  def invalid?(invoice, next_state)
    if next_state == 'reminded' && invoice.invoice_config.payment_reminder_configs.empty?
      result.track_error('payment_reminders_missing', invoice)
    elsif send_email? && !invoice.recipient_email
      result.track_error(:recipient_email_invalid, invoice)
    elsif next_state.nil?
      result.track_error("#{invoice.state}_invalid", invoice)
    end
  end

  def track_state_change(invoice, next_state)
    next_state = 'issued' if next_state == 'sent' # Always track sent as issued
    result.track_update(next_state, invoice) unless changed_from_issued_to_sent?(invoice)
  end

  def handle_email(invoice)
    enqueue_send_job(invoice)
    result.track_update(:send_notification, invoice)
  end

  def create_reminder(invoice)
    attributes = payment_reminder_attrs(invoice.payment_reminders, invoice.invoice_config)
    invoice.payment_reminders.create!(attributes)
  end

  def compute_next_state(invoice)
    if invoice.draft?
      send_email? ? 'sent' : 'issued'
    elsif invoice.issued? && send_email?
      'sent'
    elsif invoice.overdue?
      'reminded'
    end
  end

  def payment_reminder_attrs(reminders, config)
    next_level = [3, reminders.size + 1].min
    config = config.payment_reminder_configs.find_by(level: next_level)
    config.slice('title', 'text', 'level').merge(due_at: Time.zone.today + config.due_days)
  end

  def changed_from_issued_to_sent?(invoice)
    invoice.previous_changes['state'] == %w(issued sent)
  end

  def enqueue_send_job(invoice)
    Invoice::SendNotificationJob.new(invoice, sender).enqueue!
  end

  def send_email?
    sender.present?
  end

  def result
    @result ||= Invoice::BatchUpdateResult.new
  end

end
