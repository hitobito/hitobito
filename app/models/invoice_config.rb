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
  include I18nEnums

  PAYMENT_SLIPS = %w(ch_es ch_bes ch_esr ch_besr).freeze

  belongs_to :group, class_name: 'Group'
  belongs_to :contact, class_name: 'Person'

  validates :group_id, uniqueness: true
  validates :address, presence: true, on: :update
  validates :payment_for, presence: true, on: :update
  validates :beneficiary, presence: true, on: :update, if: proc { |ic| ic.ch_bes? || ic.ch_besr? }


  # TODO: probably the if condition is not correct, it has to be specified by the product owner
  validates :iban, presence: true, on: :update, if: proc { |ic| ic.ch_es? || ic.ch_bes? }
  validates :iban, format: { with: /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){12,30}\z/ },
                   on: :update, allow_blank: true

  validates :account_number, presence: true, on: :update
  validates :account_number, format: { with: /\A[0-9][-0-9]{4,20}[0-9]\z/ },
                             on: :update, allow_blank: true

  i18n_enum :payment_slip, PAYMENT_SLIPS

  validates_by_schema

  def to_s
    [model_name.human, group.to_s].join(' - ')
  end

  PAYMENT_SLIPS.each do |payment_slip|
    scope payment_slip.to_sym, -> { where(payment_slip: payment_slip) }
    define_method "#{payment_slip}?" do
      self.payment_slip == payment_slip
    end
  end

end
