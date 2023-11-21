# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleDecorator < ApplicationDecorator
  decorates :role

  def for_aside
    text = content_tag(:strong, model.to_s)
    return text unless model.outdated?

    safe_join(
      [helpers.icon(:exclamation_triangle, title: outdated_role_title), text],
      FormatHelper::EMPTY_STRING
    )
  end

  def outdated_role_title
    case model
    when FutureRole
      translate(:outdated_future_role, date: I18n.l(model.convert_on))
    else
      translate(:outdated_deleted_role, date: I18n.l(model.delete_on))
    end
    name = content_tag(:strong, model.to_s)

    if model.terminated
      terminated = content_tag(:span, translate('terminates_on', date: l(model.terminated_on)))
    end

    safe_join([name, terminated].compact, tag.br)
  end

  alias_method :for_history, :for_aside
end
