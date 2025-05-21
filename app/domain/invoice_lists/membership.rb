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
        return unless layers_without_roles?

        I18n.t(".recipient_role_group_mismatch", scope: "invoice_lists/membership", groups: layer_names_with_missing_receiver_role)
      end

      # Prepares an invoice_list for membership invoices, sets issued_at, items and calcuates items
      def prepare(invoice_list, calculate:)
        invoice_list.recipient_ids = recipient_ids(Time.zone.today.year)
        invoice_list.invoice.issued_at = Time.zone.today
        invoice_list.invoice.invoice_items = InvoiceLists::Membership.build_invoice_items
        return unless calculate

        invoice_list.invoice.invoice_items.each(&:calculate_amount) # has to be done once items reference an invoice
        invoice_list.invoice.invoice_items.each(&:recalculate)      # must be done after calculate
      end

      def recipient_ids(year)
        roles
          .where(groups: {layer_group_id: groups_with_unbilled_roles_in(year).select("layer_group_id")})
          .map(&:person_id)
      end

      def build_invoice_items = fees.map do |fee|
        InvoiceItem::Membership.new(dynamic_cost_parameters: fee.to_h.merge(fixed_fees: :memberships))
      end

      def find_layer_group(recipient) = roles.find_by(person_id: recipient.id).group.layer_group

      def roles
        Role
          .where(type: recipient.roles)
          .joins(:group)
          .order(:layer_group_id, Arel.sql(order_by_roles_statement))
          .select("DISTINCT ON (groups.layer_group_id) roles.*, groups.layer_group_id")
      end

      private

      def layer_names_with_missing_receiver_role
        layers.where.not(id: roles.map { |r| r.group.layer_group_id }).map(&:name).join(", ")
      end

      def groups_with_unbilled_roles_in(year)
        Group
          .joins(:roles)
          .where(roles: {type: config.fees.map(&:roles).flatten})
          .joins("LEFT JOIN invoice_item_roles ON invoice_item_roles.role_id = roles.id AND invoice_item_roles.year = #{year}")
          .where(invoice_item_roles: {role_id: nil})
      end

      def order_by_roles_statement
        recipient.roles.map.with_index do |role, index|
          " WHEN roles.type = '#{role}' THEN #{index}"
        end.prepend("CASE").append("END").join("\n")
      end

      def layers_without_roles? = layers.count != roles.to_a.size

      def layers = recipient.layer.constantize.all

      def config = Settings.invoices.membership
    end
  end
end
