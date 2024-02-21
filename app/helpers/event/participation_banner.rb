# frozen_string_literal: true

#  Copyright (c) 2012-2022, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationBanner

  delegate :t, :action_button, :can?, :group_event_participation_path,
           :content_tag, :safe_join, :parent, to: :@context
  delegate :pending?, :waiting_list?, to: :@user_participation

  def initialize(user_participation, event, context)
    @user_participation = user_participation
    @event = event
    @context = context
  end

  def render
    content_tag(:div, class: status_class) do
      safe_join(banner_content)
    end
  end

  def banner_content
    content = [status_text]
    if can_destroy?
      content << action_button_cancel_participation
    end
    content
  end

  def status_text
    key = if waiting_list?
            'waiting_list'
          elsif pending?
            'pending'
          else
            'explanation'
          end

    t("event.participations.cancel_application.#{key}")
  end

  def status_class
    alert_class = pending? ? 'warning' : 'success'
    "alert alert-#{alert_class}"
  end

  def can_destroy?
    can?(:destroy, @user_participation)
  end

  def action_button_cancel_participation
    action_button(
      t('event.participations.cancel_application.caption'),
      group_event_participation_path(parent, @event, @user_participation),
      'times-circle',
      data: {
        confirm: t('event.participations.cancel_application.confirmation'),
        method: :delete
      },
      class: 'ms-2'
    )
  end

end
