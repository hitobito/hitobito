# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

  def format_role_created_at(role)
    f(role.created_at.to_date)
  end

  def format_role_deleted_at(role)
    f(role.deleted_at.to_date) if role.deleted_at
  end

  def format_role_group_id(role)
    group = role.group
    if group
      link_to(group, group)
    else
      group = Group.with_deleted.where(id: role.group_id).first
      group.to_s + " (#{t('attributes.deleted_info')})"
    end
  end

  def group_options_with_level
    options = []
    base_level = nil
    Group.each_with_level(@group_selection) do |group, level|
      base_level ||= level
      label = ('&nbsp; ' * (level - base_level)).html_safe + h(group.to_s)
      options << [label, group.id]
    end
    options
  end
end
