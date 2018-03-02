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

  def call
    invoices.each do |invoice|
      state = next_state(invoice)
      next result.track_error("#{invoice.state}_invalid", invoice) unless state

      update(invoice, state)
    end

    result
  end

  private

  def update(invoice, state)
    if send_email?
      update_state_and_send(invoice, state)
    else
      update_state(invoice, state)
    end

    create_reminder(invoice) if invoice.overdue?
  end

  def next_state(invoice)
    if invoice.draft?
      send_email? ? 'sent' : 'issued'
    elsif invoice.issued? && send_email?
      'sent'
    elsif invoice.overdue?
      'reminded'
    end
  end

  def next_due_at(invoice)
    today = Time.zone.today
    today + invoice.invoice_config.due_days.days if invoice.due_at < today
  end

  def create_reminder(invoice)
    attributes = payment_reminder_attrs(invoice.payment_reminders, invoice.invoice_config)
    invoice.payment_reminders.create!(attributes)
  end

  def payment_reminder_attrs(reminders, config)
    next_level = [3, reminders.size + 1].min
    config = config.payment_reminder_configs.find_by(level: next_level)
    config.slice('title', 'text', 'level').merge(due_at: Time.zone.today + config.due_days)
  end

  def update_state(invoice, state)
    previous_state = invoice.state
    invoice.update(state: state)
    track_update(state, invoice) unless issued_to_sent?(previous_state, state)
  end

  def track_update(state, invoice)
    state = 'issued' if state == 'sent' # Always track sent as issued
    result.track_update(state, invoice)
  end

  def issued_to_sent?(previous_state, current_state)
    previous_state == 'issued' && current_state == 'sent'
  end

  def update_state_and_send(invoice, state)
    if invoice.recipient_email
      update_state(invoice, state)
      enqueue_send_job(invoice)
      result.track_update(:send_notification, invoice)
    else
      result.track_error(:recipient_email, invoice)
    end
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
