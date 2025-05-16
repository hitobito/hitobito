# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class InvoiceItem::Membership < InvoiceItem
  attr_reader :role_types

  def initialize(...)
    super
    @role_types = dynamic_cost_parameters[:roles]

    self[:unit_cost] = dynamic_cost_parameters.fetch(:unit_cost)
    self[:name] = I18n.t(dynamic_cost_parameters.fetch(:name), scope: model_name.i18n_key, locale: invoice&.recipient&.language)
  end

  def calculate_amount(recipient: nil)
    layer_group_id = InvoiceLists::Membership.find_layer_group(recipient) if recipient
    self.count = roles_count(layer_group_id:).count.values.sum
  end

  def roles_count(layer_group_id: nil)
    Role.where(type: role_types)
      .joins(:group)
      .then { |scope| layer_group_id ? scope.where(groups: {layer_group_id:}) : scope }
      .group("groups.layer_group_id")
  end
end
