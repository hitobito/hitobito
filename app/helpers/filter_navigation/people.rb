# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class People < Base

    PREDEFINED_FILTERS = %w(Mitglieder Externe)

    attr_reader :group, :name, :role_types, :deep

    delegate :can?, to: :template

    def initialize(template, group, name, role_types, deep = false)
      super(template)
      @group = group
      @name = name
      @role_types = role_types
      @deep = deep
      init_labels
      init_items
      init_dropdown_links
    end

    private

    def init_labels
      if name.present?
        if PREDEFINED_FILTERS.include?(name)
          @active_label = name
        else
          dropdown.label = name
          dropdown.active = true
        end
      elsif role_types.present?
        dropdown.label = 'Eigener Filter'
        dropdown.active = true
      else
        @active_label = PREDEFINED_FILTERS.first
      end
    end

    def init_items
      item('Mitglieder', filter_path)
      if can?(:index_local_people, group)
        item('Externe',
             filter_path(role_types: Role.external_types.collect(&:sti_name),
                         name: 'Externe'))
      end
    end

    def init_dropdown_links
      if group.layer?
        add_custom_people_filter_links
        add_define_custom_people_filter_link
      end
    end

    def add_custom_people_filter_links
      filters = PeopleFilter.for_group(group)
      filters.each { |filter| people_filter_link(filter) }
    end

    def add_define_custom_people_filter_link
      if can?(:new, group.people_filters.new)
        link = template.new_group_people_filter_path(group.id, people_filter: { role_types: role_types })
        dropdown.divider if dropdown.items.present?
        dropdown.item('Neuer Filter...', link)
      end
    end

    def people_filter_link(filter)
       link = filter_path(kind: 'deep', role_types: filter.role_types, name: filter.name)

       if can?(:destroy, filter)
         sub_item = [template.icon(:trash),
                     template.group_people_filter_path(group, filter),
                     data: { confirm: template.ti(:confirm_delete),
                             method:  :delete }]
         dropdown.item(filter.name, link, sub_item)
       else
         dropdown.item(filter.name, link)
       end
    end

    def filter_path(options = {})
      template.group_people_path(group, options)
    end

  end
end
