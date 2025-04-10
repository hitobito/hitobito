#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payment_reminder_configs
#
#  id                :integer          not null, primary key
#  due_days          :integer          not null
#  level             :integer          not null
#  text              :string           not null
#  title             :string           not null
#  invoice_config_id :integer          not null
#
# Indexes
#
#  index_payment_reminder_configs_on_invoice_config_id  (invoice_config_id)
#

class PaymentReminderConfig < ActiveRecord::Base
  include Globalized
  translates :title, :text

  belongs_to :invoice_config

  validates :title, :text, length: {maximum: 255}

  validates_by_schema

  LEVELS = (1..3)
  DEFAULTS = [
    [
      30,
      "Zahlungserinnerung",
      "Im hektischen Alltag kann es vorkommen, eine fällige Zahlung zu übersehen. " \
      "\nDanke, dass Sie die Überweisung in den nächsten " \
      "Tagen vornehmen. Sollten Sie die Zahlung bereits veranlasst haben, betrachten Sie bitte " \
      "dieses Schreiben als gegenstandslos."
    ],
    [
      14,
      "Zweite Mahnung",
      "Trotz unserer Zahlungserinnerung haben Sie unsere Rechnung noch " \
      "nicht beglichen.\nWir bitten Sie den fehlbaren Betrag zu begleichen."
    ],
    [
      5,
      "Dritte Mahnung",
      "Wir fordern Sie nun ein letztes Mal auf, den offenen Betrag innert Wochenfrist " \
      "zu begleichen."
    ]
  ].zip(LEVELS.to_a).to_h.invert

  validates :level, length: {in: LEVELS}

  scope :list, -> { order(:level) }

  def with_defaults(level)
    due_days, title, text = DEFAULTS.fetch(level)
    self.attributes = {due_days: due_days, title: title, text: text, level: level}
  end
end
