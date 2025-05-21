# frozen_string_literal: true

# == Schema Information
#
# Table name: invoice_items
#
#  id                      :integer          not null, primary key
#  account                 :string
#  cost                    :decimal(12, 2)
#  cost_center             :string
#  count                   :integer          default(1), not null
#  description             :text
#  dynamic_cost_parameters :text
#  name                    :string           not null
#  type                    :string           default("InvoiceItem"), not null
#  unit_cost               :decimal(12, 2)   not null
#  vat_rate                :decimal(5, 2)
#  invoice_id              :integer          not null
#
# Indexes
#
#  index_invoice_items_on_invoice_id    (invoice_id)
#  invoice_items_search_column_gin_idx  (search_column) USING gin
#

class InvoiceItem::Membership < InvoiceItem
  attr_reader :role_types

  validates :count, numericality: {only_integer: true, greater_than: 0}
  has_many :invoice_item_roles, foreign_key: :invoice_item_id, inverse_of: :invoice_item, dependent: :delete_all

  after_create :create_invoice_item_roles

  def initialize(...)
    super
    @role_types = dynamic_cost_parameters[:roles]
    self[:unit_cost] = dynamic_cost_parameters.fetch(:unit_cost)
    self[:name] = I18n.t(dynamic_cost_parameters.fetch(:name), scope: model_name.i18n_key, locale: invoice&.recipient&.language)
  end

  def calculate_amount(layer_group_id = nil)
    self.count = roles_scope(layer_group_id:).group("groups.layer_group_id").count.values.sum
  end

  def roles_scope(layer_group_id: nil)
    Role
      .where(type: role_types)
      .joins(:group)
      .joins("LEFT JOIN invoice_item_roles ON invoice_item_roles.role_id = roles.id AND invoice_item_roles.year = #{invoice_year}")
      .where(invoice_item_roles: {role_id: nil})
      .then { |scope| layer_group_id ? adjust_for_layer_group(scope, layer_group_id) : scope }
  end

  private

  def adjust_for_layer_group(scope, layer_group_id)
    scope
      .where(groups: {layer_group_id:})
      .tap do |scope|
        self[:dynamic_cost_parameters][:layer_group_id] = layer_group_id
        self[:dynamic_cost_parameters][:role_ids] = scope.pluck("roles.id")
      end
  end

  def create_invoice_item_roles
    attrs = dynamic_cost_parameters[:role_ids].map do |id|
      {role_id: id, invoice_item_id: self.id, year: invoice_year, layer_group_id: dynamic_cost_parameters[:layer_group_id]}
    end
    InvoiceItemRole.insert_all(attrs)
  end

  def invoice_year = invoice.issued_at.year
end
