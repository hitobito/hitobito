# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payments
#
#  id                       :integer          not null, primary key
#  amount                   :decimal(12, 2)   not null
#  received_at              :date             not null
#  reference                :string(255)
#  transaction_identifier   :string(255)
#  invoice_id               :integer          not null
#
# Indexes
#
#  index_payments_on_invoice_id  (invoice_id)
#

class Payment < ActiveRecord::Base

  belongs_to :invoice

  validates :reference, uniqueness: { scope: :invoice_id, allow_nil: true, case_sensitive: false }
  validates :transaction_identifier, uniqueness: { allow_nil: true, case_sensitive: false }

  before_validation :set_received_at
  after_create :update_invoice

  scope :list, -> { order(received_at: :desc) }

  attr_writer :esr_number

  validates_by_schema

  def group
    invoice.group
  end

  def settles?
    invoice && invoice.amount_open == amount
  end

  def exceeds?
    invoice && amount > invoice.amount_open
  end

  def undercuts?
    invoice && amount < invoice.amount_open
  end

  def difference
    invoice && amount - invoice.amount_open
  end

  def esr_number
    invoice ? invoice.esr_number : @esr_number
  end

  private

  def assert_invoice_state
    unless invoice.payable?
      errors.add(:invoice, :invalid)
    end
  end

  def update_invoice
    if amount >= invoice.amount_open(without: id)
      invoice.update(state: :payed)
    end
  end

  def set_received_at
    self.received_at ||= Time.zone.today
  end

end
