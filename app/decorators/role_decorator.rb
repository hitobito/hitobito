# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleDecorator < ApplicationDecorator
  decorates :role

  def for_aside
    formatted_name(strong: true, show_end_on: true, show_start_on: true)
  end

  def for_history
    formatted_name
  end

  def for_oauth
    {
      group_id: group_id,
      group_name: group.name,
      role: object.class.model_name,
      role_class: object.class.model_name,
      role_name: object.class.model_name.human,
      permissions: role.class.permissions.uniq
    }
  end

  private

  def formatted_name(strong: false, show_end_on: false, show_start_on: false)
    role_name = model.to_s(:short)
    name = strong ? content_tag(:strong, role_name) : role_name
    name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.label})"]) if model.label?
    name = future_role_details(name, show_start_on)
    name = end_on_details(name, show_end_on)
    terminated_details(name)
  end

  def future_role_details(name, show_start_on)
    if show_start_on && model.future?
      name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.formatted_start_date})"])
    end
    name
  end

  def end_on_details(name, show_end_on)
    if show_end_on && model.end_on? && !model.terminated?
      name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.formatted_delete_date})"])
    end
    name
  end

  def formatted_start_date
    I18n.t("global.start_on", date: I18n.l(convert_on))
  end

  def terminated_details(name)
    if model.terminated?
      terminated = content_tag(:span, translate("terminates_on", date: l(model.terminated_on)))
      name = safe_join([name, terminated].compact, tag.br)
    end
    name
  end
end
