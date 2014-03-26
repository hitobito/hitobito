# encoding: utf-8
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:event_participation, class_name: 'Event::Participation') do
  person
  event
end
