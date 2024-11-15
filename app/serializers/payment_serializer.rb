#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payments
#
#  id                     :integer          not null, primary key
#  amount                 :decimal(12, 2)   not null
#  received_at            :date             not null
#  reference              :string
#  status                 :string
#  transaction_identifier :string
#  transaction_xml        :text
#  invoice_id             :integer
#
# Indexes
#
#  index_payments_on_invoice_id              (invoice_id)
#  index_payments_on_transaction_identifier  (transaction_identifier) UNIQUE
#

class PaymentSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :amount,
      :received_at,
      :reference
  end
end
