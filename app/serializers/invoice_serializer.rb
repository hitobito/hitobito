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
#  title                       :string(255)      not null
#  sequence_number             :string(255)      not null
#  state                       :string(255)      default("draft"), not null
#  esr_number                  :string(255)      not null
#  description                 :text(65535)
#  recipient_email             :string(255)
#  recipient_address           :text(65535)
#  sent_at                     :date
#  due_at                      :date
#  group_id                    :integer          not null
#  recipient_id                :integer
#  total                       :decimal(12, 2)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_number              :string(255)
#  address                     :text(65535)
#  issued_at                   :date
#  iban                        :string(255)
#  payment_purpose             :text(65535)
#  payment_information         :text(65535)
#  payment_slip                :string(255)      default("ch_es"), not null
#  beneficiary                 :text(65535)
#  payee                       :text(65535)
#  participant_number          :string(255)
#  creator_id                  :integer
#  participant_number_internal :string(255)
#  vat_number                  :string(255)
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
    group_template_link  "#{type_name}.group"

    entity :group, item.group, GroupLinkSerializer

    entities :invoice_items, item.invoice_items, InvoiceItemSerializer
    entities :payments, item.payments, PaymentSerializer
    entities :payment_reminders, item.payment_reminders, PaymentReminderSerializer
  end
end

