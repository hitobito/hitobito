# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceItemResource < ApplicationResource
  self.readable_class = JsonApi::InvoiceAbility
  self.acceptable_scopes += %w[invoices]

  with_options filterable: false, sortable: false do
    attribute :invoice_id, :integer, filterable: true
    attribute :name, :string
    attribute :description, :string

    attribute :unit_cost, :float
    attribute :vat_rate, :float

    attribute :cost, :integer
    attribute :count, :integer
    attribute :cost_center, :string
    attribute :account, :string
  end

  belongs_to :invoice
end
