# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceNew < Base
    delegate :current_ability, to: :template
    def initialize(template, people: [], mailing_list: nil, filter: nil, # rubocop:disable Metrics/ParameterLists
      group: nil, event: nil, invoice_items: nil, label: nil)
      super(template, label, :plus)
      @people = people
      @group = group
      @mailing_list = mailing_list
      @event = event
      @label = label
      filter = filter.to_unsafe_h if filter.is_a?(ActionController::Parameters)
      @filter = filter.to_h.symbolize_keys.slice(:range, :filters).compact.presence
      init_items
    end

    def button_or_dropdown
      if finance_groups.one? && (additional_sub_links.none? ||
                                 finance_groups.first&.invoice_config&.invalid?)
        single_button
      else
        to_s
      end
    end

    private

    def label
      @label || I18n.t("crud.new.title", model: Invoice.model_name.human)
    end

    def single_button
      finance_group = finance_groups.first
      options = {}
      options[:data] = {checkable: true} if template.action_name == "index"
      options[:disabled] = invalid_config_error_msg if finance_group&.invoice_config&.invalid?
      template.action_button(label, path(finance_group), :plus, options)
    end

    # rubocop:todo Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def path(finance_group, invoice_items = []) # rubocop:disable Metrics/MethodLength
      if @mailing_list
        template.new_group_invoice_run_path(
          finance_group,
          invoice_run: {recipient_source_id: @mailing_list.id,
                        recipient_source_type: @mailing_list.class},
          invoice_items: invoice_items
        )
      elsif @event
        template.new_group_invoice_run_path(
          finance_group,
          filter: (@filter || {}).merge(event_id: @event.id),
          invoice_items: invoice_items
        )
      elsif @filter
        template.new_group_invoice_run_path(
          finance_group,
          filter: @filter.merge(group_id: @group.id),
          invoice_items: invoice_items
        )
      elsif @group
        template.new_group_invoice_run_path(
          finance_group,
          filter: {group_id: @group.id, range: "group"},
          invoice_items: invoice_items
        )
      elsif @people.one?
        template.new_group_invoice_path(
          finance_group,
          invoice: {
            recipient_id: @people.first.id,
            recipient_type: "Person"
          },
          invoice_items: invoice_items
        )
      else
        template.new_group_invoice_run_path(
          finance_group,
          ids: @people.collect(&:id).join(","),
          invoice_items: invoice_items
        )
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    def init_items # rubocop:todo Metrics/AbcSize
      if additional_sub_links.none?
        @items = finance_groups_items
      elsif finance_groups.one?
        add_item(translate(:invoice), path(finance_groups.first))
        additional_sub_links.each do |key|
          add_item(translate(key), path(finance_groups.first, [key]))
        end
      else
        item = add_item(translate(:invoice), "#")
        item.sub_items += finance_groups_items
        additional_sub_links.each do |label_key|
          item = add_item(translate(label_key), "#")
          item.sub_items += finance_groups_items([label_key])
        end
      end
    end

    def finance_groups_items(invoice_items = [])
      finance_groups.map do |finance_group|
        disabled_msg = invalid_config_error_msg if finance_group.invoice_config&.invalid?
        Item.new(finance_group.name, path(finance_group, invoice_items), disabled_msg: disabled_msg)
      end
    end

    def finance_groups
      # rubocop:todo Layout/LineLength
      @finance_groups ||= Group.where(id: current_ability.user_finance_layer_ids).includes(:invoice_config)
      # rubocop:enable Layout/LineLength
    end

    def invalid_config_error_msg
      I18n.t("activerecord.errors.models.invoice_config.not_valid")
    end

    def additional_sub_links
      InvoiceItem.type_mappings.keys
    end
  end
end
