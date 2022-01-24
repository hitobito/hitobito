# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceNew < Base
    def initialize(template, people: [], mailing_list: nil, filter: nil, group: nil)
      super(template, label, :plus)
      @people = people
      @group = group
      @mailing_list = mailing_list
      if filter.is_a?(ActionController::Parameters)
        @filter = filter.to_unsafe_h.slice(:range, :filters).compact.presence
      end
      init_items
    end

    def button_or_dropdown
      if finance_groups.one?
        single_button
      else
        to_s
      end
    end

    private

    def label
      I18n.t('crud.new.title', model: Invoice.model_name.human)
    end

    def single_button
      data = { checkable: true } if template.action_name == 'index'
      template.action_button(label, path(finance_groups.first), :plus, data: data)
    end

    def path(finance_group) # rubocop:disable Metrics/MethodLength
      if @mailing_list
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { receiver_id: @mailing_list.id, receiver_type: @mailing_list.class }
        )
      elsif @filter
        template.new_group_invoice_list_path(
          finance_group,
          filter: @filter.merge(group_id: @group.id), invoice_list: { recipient_ids: '' }
        )
      elsif @group
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { receiver_id: @group.id, receiver_type: @group.class.base_class }
        )
      elsif @people.one?
        template.new_group_invoice_path(
          finance_group,
          invoice: { recipient_id: @people.first.id }
        )
      else
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { recipient_ids: @people.collect(&:id).join(',') }
        )
      end
    end

    def init_items
      finance_groups.each do |finance_group|
        add_item(finance_group.name, path(finance_group))
      end
    end

    def finance_groups
      template.current_user.finance_groups
    end
  end
end
