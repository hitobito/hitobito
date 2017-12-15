# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoice_configs
#
#  id                  :integer          not null, primary key
#  sequence_number     :integer          default(1), not null
#  due_days            :integer          default(30), not null
#  group_id            :integer          not null
#  contact_id          :integer
#  page_size           :integer          default(15)
#  address             :text(65535)
#  payment_information :text(65535)
#

class InvoiceConfig < ActiveRecord::Base
  include PaymentSlips

  belongs_to :group, class_name: 'Group'
  belongs_to :contact, class_name: 'Person'

  validates :group_id, uniqueness: true
  validates :address, presence: true, on: :update
  validates :payee, presence: true, on: :update
  validates :beneficiary, presence: true, on: :update, if: :bank?


  # TODO: probably the if condition is not correct, verification needed
  validates :iban, presence: true, on: :update, if: :without_reference?
  validates :iban, format: { with: /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){12,30}\z/ },
                   on: :update, allow_blank: true

  validates :account_number, presence: true, on: :update
  validates :account_number, format: { with: /\A[0-9]{2}-[0-9]{2,20}-[0-9]\z/ },
                             on: :update, allow_blank: true
  validate :correct_address_wordwrap, if: :bank?
  validate :correct_check_digit


  validates_by_schema

  def to_s
    [model_name.human, group.to_s].join(' - ')
  end

  private

  def correct_address_wordwrap
    return if payee.split(/\n/).length <= 2
    errors.add(:payee, :to_long)
  end

  def correct_check_digit
    return if account_number.blank?
    payment_slip = Invoice::PaymentSlip.new
    splitted = account_number.delete('-').split('')
    check_digit = splitted.pop
    return if payment_slip.check_digit(splitted.join) == check_digit.to_i
    errors.add(:account_number, :invalid_check_digit)
  end
end
