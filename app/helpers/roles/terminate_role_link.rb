# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac

class Roles::TerminateRoleLink
  include TerminationsHelper

  delegate :can?, :link_to, :button_tag, :content_tag, :t, to: :@view

  def initialize(role, view)
    @role = role
    @view = view
  end

  def render
    return unless @role.terminatable?

    can?(:terminate, @role) ? render_link : render_disabled_button
  end

  private

  def render_link
    link_to(t('roles/terminations.global.title'),
            @view.new_group_role_termination_path(role_id: @role.id, group_id: @role.group&.id),
            class: 'btn btn-xs float-right',
            remote: true)
  end

  def render_disabled_button
    content_tag(:div, rel: 'tooltip', title: disabled_tooltip) do
      button_tag(
        t('roles/terminations.global.title'),
        class: 'btn btn-xs float-right',
        disabled: true
      )
    end
  end

  def disabled_tooltip
    key, *defaults = role_ancestors_i18n_keys(@role, :no_permission)
    t(key, default: defaults)
  end

end
