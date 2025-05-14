# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class InvoiceItem::Membership < InvoiceItem
  def self.build_all
    Settings.invoices.membership.fees.map do |config|
      new(dynamic_cost_parameters: config.to_h)
    end
  end

  attr_reader :recipient_role, :role_types

  def initialize(...)
    super
    @role_types = dynamic_cost_parameters[:roles]
    @recipient_role = Settings.invoices.membership.recipient_role # NOTE should cover multiple

    self[:unit_cost] = dynamic_cost_parameters.fetch(:unit_cost)
    self[:name] = dynamic_cost_parameters.fetch(:name)
  end

  def calculate_amount(recipient: nil)
    layer_group_id = find_layer_group_id(recipient) if recipient
    self.count = roles_count(layer_group_id:).count.values.sum
  end

  def find_layer_group_id(recipient)
    recipient.roles.find_by(type: recipient_role).group.layer_group_id
  end

  def roles_count(layer_group_id: nil)
    Role.where(type: role_types)
      .joins(:group)
      .then { |scope| layer_group_id ? scope.where(groups: {layer_group_id:}) : scope }
      .group("groups.layer_group_id")
  end
end
