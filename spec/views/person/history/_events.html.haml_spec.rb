#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person/history/_events.html.haml" do
  include FormatHelper

  let(:current_user) { people(:top_leader) }
  let(:participation) { event_participations(:top) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(controller).to receive_messages(current_user: current_user)
    assign(:participations_by_event_type, {"Events" => [participation.decorate]})
  end

  it "displays role labels as a link" do
    expect(dom).to have_css("table td a", text: "Hauptleitung")
  end
end
