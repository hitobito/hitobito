# encoding: utf-8

# == Schema Information
#
# Table name: payments
#
#  id          :integer          not null, primary key
#  amount      :decimal(12, 2)   not null
#  received_at :date             not null
#  reference   :string(255)
#  invoice_id  :integer          not null
#
# Indexes
#
#  index_payments_on_invoice_id  (invoice_id)
#

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentSerializer < ApplicationSerializer

  schema do
    json_api_properties

    map_properties :amount,
                   :received_at,
                   :reference
  end
end

