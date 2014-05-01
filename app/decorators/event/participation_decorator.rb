# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'

  decorates_association :person
  decorates_association :event, with: EventDecorator
  decorates_association :application

  delegate :to_s, :email, :primary_email, :all_emails, :all_additional_emails,
           :all_phone_numbers, :all_social_accounts, :complete_address, :town, to: :person
  delegate :priority, :confirmation, to: :application
  delegate :qualified?, to: :qualifier

  # render a list of all participations
  def roles_short
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def issue_action(group)
    if qualified.nil? || !qualified?
      qualify_action_link(group, :put, :ok)
    else
      h.icon(:ok)
    end
  end

  def revoke_action(group)
    if qualified.nil? || qualified?
      qualify_action_link(group, :delete, :remove)
    else
      h.icon(:remove)
    end
  end

  def qualify_action_link(group, method, icon)
    h.link_to(h.group_event_qualification_path(group, event_id, model),
              method: method, remote: true, title: tooltips[icon]) do
      h.content_tag(:i, '', class: "icon icon-#{icon} disabled")
    end
  end

  def waiting_list_link(group, event)
    if application
      h.toggle_link(application.waiting_list?,
                    h.waiting_list_group_event_application_market_path(group, event, id),
                    translate('waiting_list_link.title_active'),
                    translate('waiting_list_link.title_inactive'),
                    translate('waiting_list_link.label'))
    end
  end

  def qualifier
    Event::Qualifier.for(model)
  end

  def list_roles
    safe_join(roles, h.tag(:br)) { |role| role.to_s }
  end

  def originating_group
    person.primary_group
  end

  def tooltips
    @tooltips ||= {
      ok: translate('tooltips.ok'),
      remove: translate('tooltips.remove')
    }
  end

end
