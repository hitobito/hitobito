#  Copyright (c) 2017-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoices
#
#  id                          :integer          not null, primary key
#  account_number              :string
#  address                     :text
#  beneficiary                 :text
#  currency                    :string           default("CHF"), not null
#  description                 :text
#  due_at                      :date
#  esr_number                  :string           not null
#  hide_total                  :boolean          default(FALSE), not null
#  iban                        :string
#  issued_at                   :date
#  participant_number          :string
#  participant_number_internal :string
#  payee                       :text
#  payment_information         :text
#  payment_purpose             :text
#  payment_slip                :string           default("ch_es"), not null
#  recipient_address           :text
#  recipient_email             :string
#  reference                   :string           not null
#  sent_at                     :date
#  sequence_number             :string           not null
#  state                       :string           default("draft"), not null
#  title                       :string           not null
#  total                       :decimal(12, 2)
#  vat_number                  :string
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
