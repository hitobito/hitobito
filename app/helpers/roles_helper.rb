# encoding: utf-8

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RolesHelper

  def role_cancel_url
    if flash[:redirect_to]
      flash[:redirect_to]
    elsif entry.new_record?
      group_people_path(entry.group_id)
    else
      group_person_path(entry.group_id, entry.person_id)
    end
  end

  def swappable_role_add_fieldset(*keys)
    title = t('roles.person_fields.text_with_alternative_link_html',
              text: t(".#{keys.last}_person"),
              link: link_to(t(".#{keys.first}_person"), '#', data: { swap: 'person-fields' }))

    visible = keys.first == :create_new ? !entry.person.changed? : entry.person.changed?
    field_set_tag(title, class: 'person-fields', style: element_visible(visible)) { yield }
  end

  def format_role_created_at(role)
    f(role.created_at.to_date)
  end

  def format_role_deleted_at(role)
    if role.archived?
      f(role.archived_at.to_date)
    elsif role.deleted_at
      f(role.deleted_at.to_date)
    end
  end

  def format_role_group_id(role)
    group = role.group
    if group
      link_to_if(can?(:show, group), group, group)
    else
      group = Group.with_deleted.where(id: role.group_id).first
      group.to_s + " (#{t('attributes.deleted_info')})"
    end
  end

  def group_options_with_level(group_selection = @group_selection)
    options = []
    base_level = nil
    Group.each_with_level(group_selection) do |group, level|
      base_level ||= level
      label = ('&nbsp; ' * (level - base_level)).html_safe + h(group.to_s)
      options << [label, group.id]
    end
    options
  end

  def roles_type_select_options(group, role)
    options = { include_blank: true }
    selected = existing_role(role) || default_role(group)
    options.merge(selected: selected)
  end

  private

  def default_role(group)
    group.default_role ? group.default_role.sti_name : nil
  end

  def existing_role(role)
    role ? role.type : nil
  end

end
