#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/application_market/_participation.html.haml" do
  let(:event) { Fabricate(:course, groups: [groups(:top_layer)]).decorate }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }
  let(:participation) { Fabricate(:event_participation, event: event) }

  before do
    assign(:event, event)
    assign(:group, group)
  end

  it "participation without application can be rendered" do
    expect { render locals: {p: participation.decorate} }.not_to raise_error
  end
end
