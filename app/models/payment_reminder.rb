# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: payment_reminders
#
#  id         :integer          not null, primary key
#  invoice_id :integer          not null
#  message    :text(65535)
#  due_at     :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PaymentReminder < ActiveRecord::Base

  attr_accessor :invoice_ids

  belongs_to :invoice
  has_one :group, through: :invoice

  validate :assert_invoice_remindable
  validates :due_at, uniqueness: { scope: :invoice_id },
                     timeliness: { after: :invoice_due_at, allow_blank: true, type: :date },
                     if: :invoice_remindable?

  after_create :update_invoice

  validates_by_schema

  delegate :due_at, :remindable?, to: :invoice, prefix: true

  scope :list, -> { order(created_at: :desc) }

  def to_s
    I18n.l(due_at)
  end

  private

  def update_invoice
    invoice.update(state: :overdue, due_at: due_at)
  end

  def assert_invoice_remindable
    unless invoice_remindable?
      errors.add(:invoice, :invalid)
    end
  end

end
