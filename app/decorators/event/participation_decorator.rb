# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'

  decorates_association :person
  decorates_association :event
  decorates_association :application

  delegate :to_s, :email, :all_phone_numbers, :complete_address,
           :primary_email, :all_social_accounts, :town, to: :person
  delegate :priority, :confirmation, to: :application
  delegate :qualified?, to: :qualifier

  # render a list of all participations
  def roles_short(event)
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def flash_info
    "von <i>#{h.h(person)}</i> in <i>#{h.h(event)}</i>".html_safe
  end

  def qualification_link(group)
    h.toggle_link(qualified?, h.group_event_qualification_path(group, event_id, model))
  end

  def waiting_list_link(group, event)
    if application
      h.toggle_link(application.waiting_list?,
                    h.waiting_list_group_event_application_market_path(group, event, id),
                    'Entfernen von der nationalen Warteliste',
                    'Hinzufügen zu der nationalen Warteliste',
                    'Warteliste')
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

end
