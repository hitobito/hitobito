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
  belongs_to :group, class_name: 'Group'
  belongs_to :contact, class_name: 'Person'

  validates :group_id, uniqueness: true
  validates :address, presence: true, on: :update
  validates :iban, format: { with: /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){16,30}\z/ }, on: :update
  validates :account_number, format: { with: /\A[0-9][-0-9]{4,20}[0-9]\z/ }, on: :update
  validate :account_number_or_iban_present?, on: :update

  validates_by_schema

  def to_s
    [model_name.human, group.to_s].join(' - ')
  end

  private

  def account_number_or_iban_present?
    # TODO: validate presence if orange or red deposit slip
    return if account_number.present? || iban.present?
    errors.add(:iban, :required) if iban.blank?
    errors.add(:account_number, :required) if account_number.blank?
  end
end
