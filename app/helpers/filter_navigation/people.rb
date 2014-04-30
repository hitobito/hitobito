# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class People < Base

    attr_reader :group, :name, :role_type_ids, :deep

    delegate :can?, to: :template

    def initialize(template, group, name, role_type_ids, deep = false)
      super(template)
      @group = group
      @name = name
      @role_type_ids = role_type_ids
      @deep = deep
      init_kind_filter_names
      init_labels
      init_items
      init_dropdown_links
    end

    private

    def init_kind_filter_names
      @kind_filter_names = {}
      Role::Kinds.each do |kind|
        @kind_filter_names[kind] = I18n.t("activerecord.attributes.role.class.kind.#{kind}.other")
      end
    end

    def init_labels
      if name.present? && @kind_filter_names.values.include?(name)
        @active_label = name
      elsif name.present?
        dropdown.activate(name)
      elsif role_type_ids.present?
        dropdown.activate(translate(:custom_filter))
      else
        @active_label = main_filter_name
      end
    end

    def init_items
      item(main_filter_name, filter_path)
      init_kind_items
    end

    def init_kind_items
      @kind_filter_names.to_a[1..-1].each do |kind, name|
        types = group.role_types.select { |t| t.kind == kind }
        if visible_role_types?(types)
          item(name, fixed_types_path(name, types))
        end
      end
    end

    def visible_role_types?(role_types)
      role_types.present? &&
        (role_types.any? { |t| t.visible_from_above } ||
         can?(:index_local_people, group))
    end

    def main_filter_name
      @kind_filter_names.values.first
    end

    def init_dropdown_links
      if group.layer?
        add_entire_layer_filter_link
      else
        add_entire_subgroup_filter_link
      end
      add_custom_people_filter_links
      add_define_custom_people_filter_link
    end

    def add_entire_layer_filter_link
      name = translate(:entire_layer)
      link = fixed_types_path(name, sub_groups_role_types, kind: 'layer')
      dropdown.item(name, link)
    end

    def add_entire_subgroup_filter_link
      name = translate(:entire_group)
      link = fixed_types_path(name, sub_groups_role_types, kind: 'deep')
      dropdown.item(name, link)
    end

    def add_custom_people_filter_links
      filters = PeopleFilter.for_group(group)
      filters.each { |filter| people_filter_link(filter) }
    end

    def add_define_custom_people_filter_link
      if can?(:new, group.people_filters.new)
        link = template.new_group_people_filter_path(
                group.id,
                people_filter: { role_type_ids: role_type_ids })
        dropdown.divider if dropdown.items.present?
        dropdown.item(translate(:new_filter), link)
      end
    end

    def people_filter_link(filter)
      link = filter_path(filter, kind: 'deep')

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

    def fixed_types_path(name, types, options = {})
      filter_path(PeopleFilter.new(role_type_ids: types.collect(&:id), name: name), options)
    end

    def filter_path(filter = nil, options = {})
      if filter
        options[:role_type_ids] ||= filter.role_type_ids_string
        options[:name] ||= filter.name
      end
      template.group_people_path(group, options)
    end

    def sub_groups_role_types
      type = group.klass
      group_types = collect_sub_group_types([type], type.possible_children)
      role_types = group_types.collect(&:role_types).flatten.uniq
      role_types.select(&:member?)
    end

    def collect_sub_group_types(all, types)
      types.each do |type|
        unless all.include?(type) || type.layer?
          all << type
          collect_sub_group_types(all, type.possible_children)
        end
      end

      all
    end

  end
end
