#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/application_market/_participation.html.haml" do
  let(:event) { Fabricate(:course, groups: [groups(:top_layer)]).decorate }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }
  let(:participation) { Fabricate(:event_participation, event: event) }
  let(:participant) { participation.participant }

  before do
    assign(:event, event)
    assign(:group, group)
  end

  it "participation without application can be rendered" do
    render(locals: {p: participation.decorate})
    expect { render locals: {p: participation.decorate} }.not_to raise_error
  end

  describe "guest" do
    let(:guest) { Fabricate(:event_guest, main_applicant: participation) }

    it "renders main applicant link for guest" do
      render(locals: {p: Fabricate(:event_participation, event:, participant: guest).decorate})
      main_participant_link = link_to(participant.to_s(:list),
        group_event_participation_path(group, event, participation))
      expect(@rendered).to include("(Gast von #{main_participant_link})")
    end

    it "does not fail if main application participation no longer exists" do
      guest_participation = Fabricate(:event_participation, event:, participant: guest)
      participation.destroy!
      render(locals: {p: guest_participation.reload.decorate})
      expect(@rendered).to include("(Gast von abgemeldeter Person)")
    end
  end
end
