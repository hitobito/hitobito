# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payments
#
#  id                     :integer          not null, primary key
#  amount                 :decimal(12, 2)   not null
#  received_at            :date             not null
#  reference              :string
#  status                 :string
#  transaction_identifier :string
#  transaction_xml        :text
#  invoice_id             :integer
#
# Indexes
#
#  index_payments_on_invoice_id              (invoice_id)
#  index_payments_on_transaction_identifier  (transaction_identifier) UNIQUE
#
class Payment < ActiveRecord::Base
  include I18nEnums

  belongs_to :invoice, optional: true

  validate :no_duplicate_transaction_identifier

  has_one :payee, inverse_of: :payment, dependent: :destroy
  accepts_nested_attributes_for :payee

  before_validation :set_received_at
  after_create :update_invoice, if: :invoice

  scope :list, -> { order(Arel.sql("(SELECT MAX(received_at) FROM payments) DESC")) }
  scope :unassigned, -> { where(invoice_id: nil) }
  # FIXIT: spec this properly
  scope :of_layer, ->(group) { where(invoice: Invoice.where(group: group.groups_in_same_layer)) }

  STATES = %w[ebics_imported xml_imported manually_created without_invoice].freeze
  i18n_enum :status, STATES
  validates :status, inclusion: {in: STATES, allow_nil: true}

  attr_writer :esr_number
  attr_accessor :legacy_transaction_identifier

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

  # Checks for duplicate payments using both the current and the legacy transaction identifier.
  # Before PR #3998, transaction_identifier was computed from fields (amount, reference, etc.).
  # PR #3998 switched to using the UETR (Unique End-to-End Transaction Reference) when available.
  # Payments already stored with a legacy identifier must still be recognised as duplicates when
  # the same transaction is re-imported from a newer CAMT file that includes a UETR.
  # See also #3998, #4199
  def no_duplicate_transaction_identifier
    identifiers_to_check = [transaction_identifier, legacy_transaction_identifier]
      .compact.map(&:downcase)

    return if identifiers_to_check.empty?

    if Payment.where("LOWER(transaction_identifier) IN (?)", identifiers_to_check)
        .where.not(id: id).exists?
      errors.add(:transaction_identifier, :taken)
    end
  end
end
