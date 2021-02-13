# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoice_configs
#
#  id                          :integer          not null, primary key
#  account_number              :string(255)
#  address                     :text(16777215)
#  beneficiary                 :text(16777215)
#  currency                    :string(255)      default("CHF"), not null
#  due_days                    :integer          default(30), not null
#  email                       :string(255)
#  iban                        :string(255)
#  participant_number          :string(255)
#  participant_number_internal :string(255)
#  payee                       :text(16777215)
#  payment_information         :text(16777215)
#  payment_slip                :string(255)      default("ch_es"), not null
#  sequence_number             :integer          default(1), not null
#  vat_number                  :string(255)
#  group_id                    :integer          not null
#
# Indexes
#
#  index_invoice_configs_on_group_id  (group_id)
#

class InvoiceConfig < ActiveRecord::Base
  include PaymentSlips
  include ValidatedEmail

  IBAN_REGEX = /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){12,30}\z/
  ACCOUNT_NUMBER_REGEX = /\A[0-9]{2}-[0-9]{2,20}-[0-9]\z/
  PARTICIPANT_NUMBER_INTERNAL_REGEX = /\A[0-9]{6}/

  belongs_to :group, class_name: "Group"

  has_many :payment_reminder_configs, dependent: :destroy

  before_validation :nullify_participant_number_internal, unless: :bank_with_reference?

  validates :group_id, uniqueness: true
  validates :payee, presence: true, on: :update
  validates :beneficiary, presence: true, on: :update, if: :bank?
  validates :email, format: Devise.email_regexp, allow_blank: true

  # TODO: probably the if condition is not correct, verification needed
  validates :iban, presence: true, on: :update, if: :qr?
  validates :iban, format: { with: IBAN_REGEX },
                   on: :update, allow_blank: true

  validates :account_number, format: { with: ACCOUNT_NUMBER_REGEX },
                             on: :update, allow_blank: true, if: :post?

  validates :participant_number, presence: true, on: :update, if: :with_reference?
  validates :participant_number_internal, presence: true, on: :update, if: :bank_with_reference?
  validates :participant_number_internal, format: { with: PARTICIPANT_NUMBER_INTERNAL_REGEX },
                                          on: :update, if: :bank_with_reference?

  validate :correct_address_wordwrap, if: :bank?
  validate :correct_check_digit

  accepts_nested_attributes_for :payment_reminder_configs

  validates_by_schema

  def to_s
    model_name.human
  end

  private

  def correct_address_wordwrap
    return if payee.to_s.split(/\n/).length <= 2
    errors.add(:payee, :to_long)
  end

  def correct_check_digit
    return if account_number.blank? || bank?
    payment_slip = Invoice::PaymentSlip.new
    splitted = account_number.delete("-").split("")
    check_digit = splitted.pop
    return if payment_slip.check_digit(splitted.join) == check_digit.to_i
    errors.add(:account_number, :invalid_check_digit)
  end

  def nullify_participant_number_internal
    self.participant_number_internal = nil
  end

end
