# encoding: utf-8
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
