# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceResource < ApplicationResource
  primary_endpoint "invoices", [:index, :show, :update]

  with_options filterable: false, sortable: false do
    attribute :title, :string
    attribute :description, :string
    attribute :state, :string
    attribute :group_id, :integer, filterable: true
    attribute :recipient_id, :integer, filterable: true
    attribute :due_at, :date
    attribute :issued_at, :date
    attribute :recipient_email, :string
    attribute :payment_information, :string
    attribute :payment_purpose, :string
    attribute :hide_total, :boolean
  end

  belongs_to :group
  belongs_to :recipient, resource: PersonResource

  has_many :invoice_items

  def index_ability
    JsonApi::InvoiceAbility.new(current_ability)
  end
end
