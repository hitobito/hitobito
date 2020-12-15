# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceNew < Base
    attr_reader :people, :mailing_list

    def initialize(template, people: [], mailing_list: nil)
      super(template, label, :plus)
      @people = people
      @mailing_list = mailing_list
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
      if mailing_list
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { receiver_id: mailing_list.id, receiver_type: mailing_list.class }
        )
      else
        template.new_group_invoice_list_path(
          finance_group,
          invoice_list: { recipient_ids: people.collect(&:id).join(',') }
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
