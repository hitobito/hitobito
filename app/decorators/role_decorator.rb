# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleDecorator < ApplicationDecorator
  decorates :role

  def for_aside
    formatted_model_name
      .then { |markup| with_outdated_info(markup) }
      .then { |markup| with_termination_line(markup) }
  end

  def for_history
    formatted_model_name(keys: :label)
      .then { |markup| with_outdated_info(markup) }
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

  def with_termination_line(markup)
    return markup unless model.terminated?

    terminated = content_tag(:span, translate(:terminates_on, date: l(model.terminated_on)))
    safe_join([markup, terminated].compact, tag.br)
  end

  def with_outdated_info(markup)
    return markup unless model.outdated?

    triangle_icon = helpers.icon(:exclamation_triangle, title: outdated_role_title)
    safe_join([triangle_icon, markup], FormatHelper::EMPTY_STRING)
  end

  def formatted_model_name(keys: default_model_name_keys)
    parts = title.parts(*keys)
    name = content_tag(:strong, title.model_name)
    parts.any? ? name + content_tag(:span, title.parts.join(' '), class: 'ms-1') : name
  end

  def default_model_name_keys
    Roles::Title::KEYS.then do |keys|
      keys.excluding(:delete_on) if model.terminated?
    end
  end

  def title
    @title ||= Roles::Title.new(model)
  end
end
