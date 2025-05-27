#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participation_contact_datas/_address_fields.html.haml" do
  let(:event) {
    EventDecorator.decorate(Fabricate(:event,
      hidden_contact_attrs:
        ["street", "housenumber", "postbox", "zip_code", "town"]))
  }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }

  before do
    allow(view).to receive(:f).and_return(StandardFormBuilder.new(:entry, participation_contact_data, view, {}))
  end

  it "should not render address if no address attributes are set to display" do
    render locals: {entry: participation_contact_data, event: event, group: group}
    expect(rendered).to_not have_text("Adresse")
  end

  def participation_contact_data
    Event::ParticipationContactData.new(event, people(:top_leader), {})
  end
end
