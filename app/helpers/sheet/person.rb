# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Person < Base

    self.parent_sheet = Sheet::Group

    tab 'global.tabs.info',
        :group_person_path,
        if: :show

    tab 'people.tabs.mailing_lists',
        :group_person_mailing_lists_path,
        if: :show_details

    tab 'people.tabs.invoices',
        :invoices_group_person_path,
        if: (lambda do |view, group, person|
          person.finance_groups.present? &&
            (view.can?(:index_invoices, group) || view.can?(:index_invoices, person))
        end)

    tab 'people.tabs.history',
        :history_group_person_path,
        if: :history

    tab 'people.tabs.log',
        :log_group_person_path,
        if: :log

    tab 'people.tabs.colleagues',
        :colleagues_group_person_path,
        if: (lambda do |_view, _group, person|
          person.company_name?
        end)

    def link_url
      view.group_person_path(parent_sheet.entry.id, entry.id)
    end

  end
end
