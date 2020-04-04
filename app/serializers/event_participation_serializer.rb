# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
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

    property :first_name, item.person.first_name
    property :last_name, item.person.last_name
    property :nickname, item.person.nickname
    property :email, item.person.email
    property :birthday, item.person.birthday&.iso8601
    property :gender, item.person.gender

    property :roles, Hash[item.roles.collect { |role| [role.class.name, role.to_s] }]
    entity :person, item.person, PersonSerializer

    map_properties :additional_information, :active, :qualified

    entities :event_answers, item.answers, EventAnswerSerializer

    person_template_link "#{type_name}.person"

    apply_extensions(:attrs)
  end
end
