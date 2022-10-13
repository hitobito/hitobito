# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceNew < Base
    class_attribute :sub_links

    self.sub_links = {
      invoice: []
    }

    def self.add_sub_link(label_key, invoice_items)
      self.sub_links[label_key] = invoice_items
    end

    def initialize(template, people: [], mailing_list: nil, filter: nil, # rubocop:disable Metrics/ParameterLists
                             group: nil, invoice_items: nil, label: nil)
      super(template, label, :plus)
      @people = people
      @group = group
      @mailing_list = mailing_list
      @label = label
      if filter.is_a?(ActionController::Parameters)
        @filter = filter.to_unsafe_h.slice(:range, :filters).compact.presence
      end
      init_items
    end

    def button_or_dropdown
      if finance_groups.one? && InvoiceItem.all_types.one?
        single_button
      else
        to_s
      end
    end

    private

    def label
      @label || I18n.t('crud.new.title', model: Invoice.model_name.human)
    end

    def single_button
      finance_group = finance_groups.first
      options = {}
      options[:data] = { checkable: true } if template.action_name == 'index'
      options[:disabled] = invalid_config_error_msg if finance_group&.invoice_config&.invalid?
      template.action_button(label, path(finance_group), :plus, options)
    end

    def path(finance_group, invoice_items = []) # rubocop:disable Metrics/MethodLength
      if @mailing_list
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { receiver_id: @mailing_list.id, receiver_type: @mailing_list.class },
          invoice_items: invoice_items
        )
      elsif @filter
        template.new_group_invoice_list_path(
          finance_group,
          filter: @filter.merge(group_id: @group.id), invoice_list: { recipient_ids: '' },
          invoice_items: invoice_items
        )
      elsif @group
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { receiver_id: @group.id, receiver_type: @group.class.base_class },
          invoice_items: invoice_items
        )
      elsif @people.one?
        template.new_group_invoice_path(
          finance_group,
          invoice: { recipient_id: @people.first.id },
          invoice_items: invoice_items
        )
      else
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { recipient_ids: @people.collect(&:id).join(',') },
          invoice_items: invoice_items
        )
      end
    end

    def init_items
      if sub_links.one?
        @items = finance_groups_items
      elsif finance_groups.one?
        sub_links.each do |label_key, invoice_item_types|
          add_item(translate(label_key), path(finance_groups.first, invoice_item_types))
        end
      else
        sub_links.each do |label_key, invoice_item_types|
          item = add_item(translate(label_key), '#')
          item.sub_items += finance_groups_items(invoice_item_types)
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
      template.current_user.finance_groups
    end

    def invalid_config_error_msg
      I18n.t('activerecord.errors.models.invoice_config.not_valid')
    end
  end
end
