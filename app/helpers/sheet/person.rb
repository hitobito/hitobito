# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Person < Base
    self.parent_sheet = Sheet::Group

    tab "global.tabs.info",
      :group_person_path,
      if: :show

    if Settings.people.abos
      tab "people.tabs.subscriptions",
        :group_person_subscriptions_path,
        if: :show_details
    end

#    tab "people.tabs.invoices",
#      :personal_invoices_group_person_path,
#      if: (lambda do |view, group, person|
#        view.can?(:index_invoices, group) || view.can?(:index_invoices, person)
#      end)

    tab "activerecord.models.message.other",
      :messages_group_person_path,
      if: (lambda do |view, _group, person|
        view.can?(:show_details, person) && (person.roles.any? || person.root?)
      end)

    tab "people.tabs.history",
      :history_group_person_path,
      if: (lambda do |view, _group, person|
        view.can?(:history, person)
      end)

    tab "people.tabs.log",
      :log_group_person_path,
      if: (lambda do |view, _group, person|
        view.can?(:log, person)
      end)

    tab "people.tabs.security_tools",
      :security_tools_group_person_path,
      if: (lambda do |view, _group, person|
        view.can?(:security, person)
      end)

    tab "people.tabs.colleagues",
      :colleagues_group_person_path,
      if: (lambda do |_view, _group, person|
        person.company_name?
      end)

    if Settings.assignments&.enabled
      tab "activerecord.models.assignment.other",
        :group_person_assignments_path,
        if: :show_details
    end

    def link_url
      view.group_person_path(parent_sheet.entry.id, entry.id)
    end
  end
end
