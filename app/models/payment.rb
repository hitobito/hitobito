# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
  include I18nEnums

  belongs_to :invoice, optional: true

  validates :transaction_identifier, uniqueness: { allow_nil: true, case_sensitive: false }

  has_one :payee, inverse_of: :payment, dependent: :destroy
  accepts_nested_attributes_for :payee

  before_validation :set_received_at
  after_create :update_invoice, if: :invoice


  scope :list, -> { order(received_at: :desc) }
  scope :unassigned, -> { where(invoice_id: nil) }

  STATES = %w(ebics_imported xml_imported manually_created without_invoice).freeze
  i18n_enum :status, STATES
  validates :status, inclusion: { in: STATES, allow_nil: true }

  attr_writer :esr_number

  validates_by_schema

  def group
    invoice.group
  end

  def settles?
    invoice && invoice.amount_open(without: id) == amount
  end

  def exceeds?
    invoice && amount > invoice.amount_open(without: id)
  end

  def undercuts?
    invoice && amount < invoice.amount_open(without: id)
  end

  def difference
    invoice && (amount - invoice.amount_open(without: id))
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
    new_state = if settles?
                  :payed
                elsif undercuts?
                  :partial
                elsif exceeds?
                  :excess
                end

    if new_state
      invoice.update(state: new_state)
    end
  end

  def set_received_at
    self.received_at ||= Time.zone.today
  end

end
