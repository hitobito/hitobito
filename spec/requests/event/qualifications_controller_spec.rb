# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper_request'

describe Event::QualificationsController do

  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk))
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  let(:group) { event.groups.first }

  let(:participant_1)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end

  let(:participant_2)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end

  before do
    # init required data
    participant_1
    participant_2
  end

  it "qualification requests are mutually undoable", js: true do
    obsolete_node_safe do
      sign_in
      visit group_event_qualifications_path(group.id, event.id)

      appl_id = "#event_participation_#{participant_1.id}"

      find("#{appl_id} td:first").should have_selector('.icon-minus')

      find("#{appl_id} td:first a").click
      find("#{appl_id} td:first").should have_selector('.icon-ok')

      find("#{appl_id} td:first a").click
      find("#{appl_id} td:first").should have_selector('.icon-minus')
    end
  end

end
