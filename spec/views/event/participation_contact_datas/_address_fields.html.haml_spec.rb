#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participation_contact_datas/_address_fields.html.haml" do
  let(:event) { Fabricate(:event, hidden_contact_attrs: ["street", "housenumber"]).decorate }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }

  before do
    allow(view).to receive(:f).and_return(StandardFormBuilder.new(:entry, participation_contact_data(event), view, {}))
  end

  [:address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country].each do |attribute|
    it "does not render input with id entry_#{attribute} when attribute is hidden" do
      event.update!(hidden_contact_attrs: [attribute])
      render locals: {entry: participation_contact_data(event), event:, group:}
      expect(rendered).not_to have_selector("input#entry_#{attribute}")
    end
  end

  it "should render address label when only housenumber is hidden" do
    event.update!(hidden_contact_attrs: [:housenumber])
    render locals: {entry: participation_contact_data(event), event: , group:}
    expect(rendered).to have_text("Adresse")
  end

  it "should not render address label if no address attributes are set to display" do
    event.update!(hidden_contact_attrs: [:housenumber, :street])
    render locals: {entry: participation_contact_data(event), event:, group:}
    expect(rendered).to have_no_text("Adresse")
  end

  def participation_contact_data(event)
    Event::ParticipationContactData.new(event, people(:top_leader), {})
  end
end
