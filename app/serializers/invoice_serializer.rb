# encoding: utf-8

#  Copyright (c) 2017-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoices
#
#  id                          :integer          not null, primary key
#  account_number              :string(255)
#  address                     :text(16777215)
#  beneficiary                 :text(16777215)
#  currency                    :string(255)      default("CHF"), not null
#  description                 :text(16777215)
#  due_at                      :date
#  esr_number                  :string(255)      not null
#  iban                        :string(255)
#  issued_at                   :date
#  participant_number          :string(255)
#  participant_number_internal :string(255)
#  payee                       :text(16777215)
#  payment_information         :text(16777215)
#  payment_purpose             :text(16777215)
#  payment_slip                :string(255)      default("ch_es"), not null
#  recipient_address           :text(16777215)
#  recipient_email             :string(255)
#  reference                   :string(255)      not null
#  sent_at                     :date
#  sequence_number             :string(255)      not null
#  state                       :string(255)      default("draft"), not null
#  title                       :string(255)      not null
#  total                       :decimal(12, 2)
#  vat_number                  :string(255)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  creator_id                  :integer
#  group_id                    :integer          not null
#  invoice_list_id             :bigint
#  recipient_id                :integer
#
# Indexes
#
#  index_invoices_on_esr_number       (esr_number)
#  index_invoices_on_group_id         (group_id)
#  index_invoices_on_invoice_list_id  (invoice_list_id)
#  index_invoices_on_recipient_id     (recipient_id)
#  index_invoices_on_sequence_number  (sequence_number)
#

class InvoiceSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :title,
      :sequence_number,
      :state,
      :esr_number,
      :description,
      :recipient_email,
      :recipient_address,
      :sent_at,
      :due_at,
      :total,
      :created_at,
      :updated_at,
      :account_number,
      :address,
      :issued_at,
      :iban,
      :payment_purpose,
      :payment_information,
      :beneficiary,
      :payee,
      :participant_number,
      :vat_number

    entity :creator, item.creator_id, PersonIdSerializer
    entity :recipient, item.recipient_id, PersonIdSerializer

    person_template_link "#{type_name}.creator"
    person_template_link "#{type_name}.recipient"
    group_template_link "#{type_name}.group"

    entity :group, item.group, GroupLinkSerializer

    entities :invoice_items, item.invoice_items, InvoiceItemSerializer
    entities :payments, item.payments, PaymentSerializer
    entities :payment_reminders, item.payment_reminders, PaymentReminderSerializer
  end
end
