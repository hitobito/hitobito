# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "event/participation_contact_datas/_person_name_fields.html.haml" do
  let(:event) { Fabricate(:event).decorate }
  let(:participation_contact_data) { Event::ParticipationContactData.new(event, people(:top_leader), {}) }
  let(:form_builder) { StandardFormBuilder.new(:entry, participation_contact_data, view, {}) }

  before do
    allow(view).to receive(:event).and_return(event)
  end

  it "renders company_name when address.company is enabled" do
    render locals: {f: form_builder}

    expect(rendered).to have_field("entry_company_name")
  end

  it "does not render company_name when address.company is disabled" do
    allow(Event).to receive(:possible_contact_attrs)
      .and_return(Event.possible_contact_attrs - [:company_name])

    render locals: {f: form_builder}

    expect(rendered).to have_no_field("entry_company_name")
  end
end
