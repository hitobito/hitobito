# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleDecorator < ApplicationDecorator
  decorates :role

  def for_aside
    formatted_name(strong: true, show_delete_on: true, show_start_on: true)
  end

  def for_history
    formatted_name
  end

  def outdated_role_title
    case model
    when FutureRole
      translate(:outdated_future_role, date: I18n.l(model.convert_on))
    else
      translate(:outdated_deleted_role, date: I18n.l(model.delete_on))
    end
  end

  private

  def formatted_name(strong: false, show_delete_on: false, show_start_on: false)
    role_name = model.to_s(:short)
    name = strong ? content_tag(:strong, role_name) : role_name
    name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.label})"]) if model.label?
    name = future_role_details(name, show_start_on)
    name = delete_on_details(name, show_delete_on)
    name = outdated_details(name)
    terminated_details(name)
  end

  def future_role_details(name, show_start_on)
    if show_start_on && model.is_a?(FutureRole)
      name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.formatted_start_date})"])
    end
    name
  end

  def delete_on_details(name, show_delete_on)
    if show_delete_on && model.delete_on? && !model.terminated?
      name = safe_join([name, FormatHelper::EMPTY_STRING, "(#{model.formatted_delete_date})"])
    end
    name
  end

  def outdated_details(name)
    if model.outdated?
      name = safe_join(
        [helpers.icon(:exclamation_triangle, title: outdated_role_title), name],
        FormatHelper::EMPTY_STRING)
    end
    name
  end

  def terminated_details(name)
    if model.terminated?
      terminated = content_tag(:span, translate('terminates_on', date: l(model.terminated_on)))
      name = safe_join([name, terminated].compact, tag.br)
    end
    name
  end

end
