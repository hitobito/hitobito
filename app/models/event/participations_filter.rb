#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_participations_filters
#
#  id               :bigint           not null, primary key
#  participant_type :string
#  event_id         :bigint
#
# Indexes
#
#  index_event_participations_filters_on_event_id  (event_id)
#
class Event::ParticipationsFilter < ActiveRecord::Base
  belongs_to :event

  def to_params
    {filters: {participant_type: participant_type}}
  end
end
