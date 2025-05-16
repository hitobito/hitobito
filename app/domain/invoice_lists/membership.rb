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

      # NOTE: dont pluck as this would clear select
      def recipient_ids = recipient_roles.map(&:person_id)

      def warning
        return nil if recipient.layer.constantize.count == recipient_ids.size
        Role.joins(:group).pluck(:layer_group_id)
        I18n.t(".recipient_role_group_mismatch", scope: ActiveModel::Name.new(self).i18n_key, groups:)
      end

      def recipient_roles
        Role
          .joins(:group)
          .where({type: recipient.roles})
          .order(:layer_group_id, :person_id, Arel.sql(order_by_roles_statement))
          .select("DISTINCT ON (groups.layer_group_id, roles.person_id) roles.*, groups.layer_group_id")
      end

      private

      def self.build_all
        Settings.invoices.membership.fees.map do |config|
          new(dynamic_cost_parameters: config.to_h)
        end
      end

      def self.warning
        layer = Settings.invoices.membership.recipient.layer.constantize
        role = Settings.invoices.membership.recipient.role.constantize

        if (layer.count != role.count) || (layer.count != role.distinct_on("group_id").count)
          "missmatch between #{layer} and #{role}"
        end
      end

      private

      def order_by_roles_statement = recipient.roles.reverse.map.with_index do |role, index|
        " WHEN roles.type = '#{role}' THEN #{index}"
      end.prepend("CASE").append("END").join("\n")

      def config = Settings.invoices.membership
    end
  end
end
