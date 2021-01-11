# encoding: utf-8
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

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:invoice) do
  title { Faker::Name.name }
end

Fabricator(:invoice_article) do
  number    { Faker::Number.hexadecimal(5).to_s.upcase }
  name      { Faker::Commerce.product_name }
  unit_cost { (Faker::Commerce.price / 0.05).to_i * 0.05.to_d }
end

Fabricator(:payment_reminder) do
  title    { Faker::Lorem.sentence }
  text     { Faker::Lorem.sentence(5) }
  level    { 1 }
end
