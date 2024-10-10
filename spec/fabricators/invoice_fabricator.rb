#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
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

Fabricator(:invoice) do
  title { Faker::Name.name }
end

Fabricator(:invoice_article) do
  number { Faker::Number.hexadecimal(digits: 5).to_s.upcase }
  name { Faker::Commerce.product_name }
  unit_cost { (Faker::Commerce.price / 0.05).to_i * BigDecimal("0.05") }
end

Fabricator(:payment_reminder) do
  title { Faker::Lorem.sentence }
  text { Faker::Lorem.sentence(word_count: 5) }
  level { 1 }
end
