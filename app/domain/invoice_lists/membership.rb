# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceLists
  class Membership
    class << self
      delegate :recipient, to: :config
      delegate :fees, to: :config

      def warning
        return nil if recipient.layer.constantize.count == recipient_ids.size

        layer_group_ids = recipient_roles.map(&:group).map(&:layer_group_id)
        groups = recipient.layer.constantize.where.not(id: layer_group_ids).map(&:to_s).join(", ")
        I18n.t(".recipient_role_group_mismatch", scope: ActiveModel::Name.new(self).i18n_key, groups:)
      end

      def recipient_roles
        Role
          .joins(:group)
          .where({type: recipient.roles})
          .order(:layer_group_id, Arel.sql(order_by_roles_statement))
          .select("DISTINCT ON (groups.layer_group_id) roles.*, groups.layer_group_id")
      end

      def invoice_items = fees.map { |fee| InvoiceItem::Membership.new(dynamic_cost_parameters: fee.to_h) }

      # NOTE: dont pluck as this would clear select
      def recipient_ids = recipient_roles.map(&:person_id)

      def find_layer_group(recipient)
        recipient_roles.find_by(person_id: recipient.id).group.layer_group if recipient
      end

      private

      def order_by_roles_statement = recipient.roles.map.with_index do |role, index|
        " WHEN roles.type = '#{role}' THEN #{index}"
      end.prepend("CASE").append("END").join("\n")

      def config = Settings.invoices.membership
    end
  end
end
