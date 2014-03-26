# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#  external_applications  :boolean          default(FALSE)
#

Fabricator(:event) do
  name { 'Eventus' }
  groups { [Group.all_types.first.first] }
  before_validation { |event| event.dates.build(start_at: Time.zone.local(2012, 05, 11)) }
end


Fabricator(:course, from: :event, class_name: :'Event::Course') do
  groups { [Group.all_types.detect { |t| t.event_types.include?(Event::Course) }.first] }
  kind { Event::Kind.where(short_name: 'SLK').first }
  priorization { true }
  requires_approval { true }
end
