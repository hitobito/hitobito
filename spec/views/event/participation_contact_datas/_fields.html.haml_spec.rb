# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participation_contact_datas/_fields.html.haml" do
  let(:event) { Fabricate(:event, hidden_contact_attrs: []).decorate }
  let(:group) { Fabricate(:group, type: "Group::TopLayer").decorate }
  let(:participation_contact_data) { Event::ParticipationContactData.new(event, people(:top_leader), {}) }
  let(:form_builder) { StandardFormBuilder.new(:entry, participation_contact_data, view, {builder: StandardFormBuilder}) }

  before do
    assign(:policy_finder, Group::PrivacyPolicyFinder.for(group: group))
    allow(view).to receive_messages(event: event, entry: participation_contact_data,
      current_user: people(:top_leader))
  end

  it "does not render language when it is hidden" do
    event.update!(hidden_contact_attrs: ["language"])

    render locals: {f: form_builder, entry: participation_contact_data, event:, group:}

    expect(rendered).not_to have_selector("select#entry_language")
  end

  it "renders language when it is not hidden" do
    render locals: {f: form_builder, entry: participation_contact_data, event:, group:}

    expect(rendered).to have_selector("select#entry_language")
  end
end
