#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationsFilter do
  let(:event) { events(:top_event) }
  let(:participations_filter) { Event::ParticipationsFilter.new(event: event, participant_type: "all") }

  it "returns all active groups of certain group_type at certain date" do
    expect(participations_filter.to_params.to_s).to eq "{:filters=>{:participant_type=>\"all\"}}"
  end
end
