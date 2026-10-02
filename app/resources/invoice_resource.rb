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
    # Like in the web UI, new invoices always start as drafts.
    attribute :state, :string, writable: :existing_invoice?
    attribute :group_id, :integer, filterable: true
    attribute :recipient_id, :integer, filterable: true
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

  before_save :assign_defaults, only: [:create]
  before_save :authorize_recipient, only: [:create]
  after_save :raise_if_invalid, only: [:create]

  # Sideposted invoice items are saved after the invoice, so its total is only known once
  # the whole request is saved. Graphiti also runs this for an invalid invoice, and
  # recalculate! saves without validating.
  after_graph_persist(only: [:create, :update]) do |invoice|
    invoice.recalculate! if invoice.errors.empty?
  end

  belongs_to :group
  belongs_to :recipient, resource: PersonResource

  has_many :invoice_items

  private

  def existing_invoice?(invoice) = invoice.persisted?

  def authorize_create(model)
    invalid_request!(:group_id, :blank) if model.group_id.blank?
    super
  end

  # Like in the web UI, only people can be invoiced individually.
  def assign_defaults(model)
    model.creator_id = current_ability.user.id
    model.recipient_type = Person.sti_name if model.recipient_id
  end

  # Graphiti would otherwise go on to save the sideposted invoice items without an invoice.
  # It rescues this error and responds with the validation errors.
  def raise_if_invalid(model)
    return if model.errors.empty?

    raise Graphiti::Errors::ValidationError.new(Graphiti::Util::ValidationResponse.new(model, nil))
  end

  # Creating an invoice copies the recipient's invoice address and e-mail onto it,
  # which the API otherwise only reveals with :show_details.
  def authorize_recipient(model)
    create_ability.authorize!(:show_details, model.recipient) if model.recipient
  end
end
