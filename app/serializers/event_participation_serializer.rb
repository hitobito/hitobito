# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text(65535)
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean

class EventParticipationSerializer < ApplicationSerializer
  schema do
    json_api_properties

    (Person::PUBLIC_ATTRS - [:id]).each do |name|
      property name, item.person.try(name)
    end

    property :birthday, item.person.birthday.try(:iso8601)
    property :roles, (item.roles.collect do |role|
      {
        type: role.class.name, # existing style
        role_class: role.class.name, # new style, consistent with other serializers
        name: role.to_s
      }
    end)

    entity :person, item.person_id, PersonIdSerializer

    map_properties :additional_information, :active, :qualified

    entities :event_answers, item.answers, EventAnswerSerializer

    person_template_link "#{type_name}.person"

    apply_extensions(:attrs)
  end
end
