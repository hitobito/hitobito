#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class People < Base
    include ParamConverters

    attr_reader :group, :filter

    delegate :can?, to: :template

    def initialize(template, group, filter)
      super(template)
      @group = group
      @filter = filter
      init_kind_filter_names
      init_labels
      init_kind_items
      init_dropdown_links
    end

    def name
      filter.name
    end

    def match
      @params[:match]
    end

    private

    def init_kind_filter_names
      @kind_filter_names = {}
      Role::Kinds.each do |kind|
        name = if group.archived?
          I18n.t("activerecord.attributes.role.class.archived",
            role_kind: I18n.t("activerecord.attributes.role.class.kind.#{kind}.other"))
        else
          I18n.t("activerecord.attributes.role.class.kind.#{kind}.other")
        end
        @kind_filter_names[kind] = name
      end
    end

    def init_labels
      if name.present? && @kind_filter_names.value?(name)
        @active_label = name
      elsif group.archived? && only_archived_filter_active?
        @active_label = main_filter_name
      elsif name.present?
        dropdown.activate(name)
      elsif filter.chain.present?
        dropdown.activate(translate(:custom_filter))
      else
        @active_label = main_filter_name
      end
    end

    def init_kind_items
      @kind_filter_names.each do |kind, name|
        role_types = filter_role_types(kind)
        next unless visible_role_types?(role_types)

        count = count_roles(role_types, future: kind == :future)
        path = kind_path(kind, name, role_types)
        item(name, path, count) unless skip_kind?(kind, count)
      end
    end

    def filter_role_types(kind)
      return group.role_types if kind == :future

      group.role_types.select { |t| t.kind == kind }
    end

    def visible_role_types?(role_types)
      role_types.present? &&
        (role_types.any?(&:visible_from_above) ||
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
      add_people_filter_links
      add_define_people_filter_link
    end

    def add_entire_layer_filter_link
      name = translate(:entire_layer)
      link = fixed_types_path(name, sub_groups_role_types, range: "layer")
      dropdown.add_item(name, link)
    end

    def add_entire_subgroup_filter_link
      name = translate(:entire_group)
      link = fixed_types_path(name, sub_groups_role_types, range: "deep")
      dropdown.add_item(name, link)
    end

    def add_people_filter_links
      filters = PeopleFilter.for_group(group).list
      filters.each { |filter| people_filter_link(filter) }
    end

    def add_define_people_filter_link
      if can?(:new, group.people_filters.new)
        dropdown.add_divider if dropdown.items.present?
        dropdown.add_item(translate(:new_filter), new_group_people_filter_path)
      end
    end

    def new_group_people_filter_path
      template.new_group_people_filter_path(
        group.id,
        range: filter.range,
        filters: filter.chain.to_params
      )
    end

    def qualification_group_people_filter_path
      template.qualification_group_people_filters_path(
        group.id,
        qualification_kind_id: qualification_kind_ids,
        kind: deep, validity: validity, match: match,
        start_at_year_from: @params[:start_at_year_from],
        start_at_year_until: @params[:start_at_year_until],
        finish_at_year_from: @params[:finish_at_year_from],
        finish_at_year_until: @params[:finish_at_year_until]
      )
    end

    def people_filter_link(filter)
      item = dropdown.add_item(filter.name, path(filter_id: filter.id))
      if can?(:destroy, filter)
        item.sub_items << edit_filter_item(filter)
        item.sub_items << delete_filter_item(filter)
      end
    end

    def delete_filter_item(filter)
      ::Dropdown::Item.new(
        filter_label(:"trash-alt", :delete),
        delete_group_people_filter_path(filter),
        data: {confirm: template.ti(:confirm_delete), method: :delete}
      )
    end

    def delete_group_people_filter_path(filter)
      template.group_people_filter_path(group, filter)
    end

    def edit_filter_item(filter)
      ::Dropdown::Item.new(
        filter_label(:edit, :edit),
        edit_group_people_filter_path(filter)
      )
    end

    def edit_group_people_filter_path(filter)
      template.edit_group_people_filter_path(group, filter)
    end

    def filter_label(icon, desc)
      template.safe_join([template.icon(icon), " ", template.t("global.link.#{desc}")])
    end

    def fixed_types_path(name, types, options = {})
      type_ids = types.collect(&:id).join(Person::Filter::Base::ID_URL_SEPARATOR)
      path(options.merge(name: name,
        filters: {role: {role_type_ids: type_ids}}))
    end

    def kind_path(kind, name, role_types)
      case kind
      when :member
        path
      when :future
        start_at = Date.current.tomorrow
        finish_at = "9999-12-31"
        path(name:, filters: {role: {start_at:, finish_at:, kind: :created}})
      else
        fixed_types_path(name, role_types)
      end
    end

    def path(options = {})
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

    def only_archived_filter_active?
      filter.chain.filters.one? &&
        filter.chain.filters.first.is_a?(Person::Filter::Role) &&
        filter.chain.filters.first.args[:role_type_ids].empty? &&
        filter.chain.filters.first.args[:role_types].empty? &&
        true?(filter.chain.filters.first.args[:include_archived])
    end

    def skip_kind?(kind, count)
      true if kind == :future && count.zero?
    end

    def count_roles(role_types, future:)
      roles_scope = Role.where(group_id: group.id, type: role_types.collect(&:sti_name))
      roles_scope = roles_scope.future if future
      people_scope = Person.joins("INNER JOIN roles ON people.id = roles.person_id")
      people_scope.merge(roles_scope).distinct.count
    end
  end
end
