# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceResource < ApplicationResource
  primary_endpoint "invoices", [:index, :create, :show, :update]

  self.readable_class = JsonApi::InvoiceAbility
  self.acceptable_scopes += %w[invoices]

  with_options filterable: false, sortable: false do
    attribute :title, :string
    attribute :description, :string
    attribute :state, :string
    attribute :group_id, :integer, filterable: true
    attribute :recipient_id, :integer, filterable: true
    attribute :recipient_type, :string
    attribute :due_at, :date
    attribute :issued_at, :date
    attribute :recipient_email, :string
    attribute :recipient_first_name, :string
    attribute :recipient_last_name, :string
    attribute :recipient_company_name, :string
    attribute :recipient_address_care_of, :string
    attribute :recipient_street, :string
    attribute :recipient_housenumber, :string
    attribute :recipient_postbox, :string
    attribute :recipient_zip_code, :string
    attribute :recipient_town, :string
    attribute :recipient_country, :string
    attribute :payment_information, :string
    attribute :payment_purpose, :string
    attribute :hide_total, :boolean
    attribute :shipping_method, :string
    attribute :pp_post, :string
  end

  belongs_to :group
  belongs_to :recipient, resource: PersonResource

  has_many :invoice_items

  private

  def authorize_create(model)
    invalid_request!(:group_id, :blank) if model.group_id.blank?
    super
  end
end
