# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceNew < Base

    # attr_reader :params

    def initialize(template, label, finance_groups, people, icon)
      super(template, label, icon)
      @finance_groups = finance_groups
      @people = people
      init_items
    end

    private

    def init_items
      finance_group_links
    end

    def finance_group_links
      @finance_groups.each do |group|
        add_item(group.name, template.new_invoices_for_people_path(group, @people))
      end
    end
  end
end
