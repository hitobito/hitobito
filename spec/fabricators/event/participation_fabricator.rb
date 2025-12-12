#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  active                 :boolean          default(FALSE), not null
#  additional_information :text
#  participant_type       :string
#  qualified              :boolean
#  created_at             :datetime
#  updated_at             :datetime
#  application_id         :integer
#  event_id               :integer          not null
#  participant_id         :integer          not null
#
# Indexes
#
#  idx_on_participant_type_participant_id_bfb6fab1d7    (participant_type,participant_id)
#  index_event_participations_on_application_id         (application_id)
#  index_event_participations_on_event_id               (event_id)
#  index_event_participations_on_participant_id         (participant_id)
#  index_event_participations_on_polymorphic_and_event  (participant_type,participant_id,event_id) UNIQUE
#
Fabricator(:event_participation, class_name: "Event::Participation") do
  participant { Fabricate(:person) }
  event
end
