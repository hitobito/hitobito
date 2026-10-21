# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "events/_general_fields", type: :request do
  let(:group) { groups(:top_group) }

  before { sign_in(people(:top_leader)) }

  def visible_contact_attribute_checkbox(name)
    Nokogiri::HTML(response.body).at_css(
      %(input[name="event[visible_contact_attributes][#{name}]]"])
    )
  end

  it "only checks default_visible_contact_attributes by default on a new event" do
    allow(Event).to receive(:default_visible_contact_attributes).and_return(%w[name email])

    get new_group_event_path(group_id: group.id, event: {type: "Event"})

    expect(visible_contact_attribute_checkbox("name")[:checked]).to eq("checked")
    expect(visible_contact_attribute_checkbox("email")[:checked]).to eq("checked")
    expect(visible_contact_attribute_checkbox("picture")[:checked]).to be_nil
    expect(visible_contact_attribute_checkbox("address")[:checked]).to be_nil
    expect(visible_contact_attribute_checkbox("phone_number")[:checked]).to be_nil
    expect(visible_contact_attribute_checkbox("social_account")[:checked]).to be_nil
  end
end
