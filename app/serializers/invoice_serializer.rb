#  Copyright (c) 2017-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class InvoiceSerializer < ApplicationSerializer
  schema do # rubocop:todo Metrics/BlockLength
    json_api_properties

    map_properties :title,
      :sequence_number,
      :state,
      :esr_number,
      :description,
      :recipient_email,
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

    property :recipient_address, item.recipient_address
    property :payee, item.payee
  end
end
