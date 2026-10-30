# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "person/history/_course_qualification.html.haml" do
  let(:participation) { event_participations(:top) }
  let(:dom) {
    render partial: "person/history/course_qualification", locals: {p: participation.decorate}
    Capybara::Node::Simple.new(rendered)
  }

  before do
    allow_any_instance_of(Event).to receive(:qualifications_visible?).and_return(true)
  end

  it "shows passed without tooltip when there is no comment" do
    participation.update_column(:qualified, true)

    expect(dom).to have_content "Bestanden"
    expect(dom).not_to have_content "Nicht bestanden"
    expect(dom).not_to have_css("i[title]")
  end

  it "shows failed with tooltip containing the comment" do
    participation.update_columns(qualified: false, qualification_comment: "Zu wenig Praxis")

    expect(dom).to have_content "Nicht bestanden"
    expect(dom).to have_css("i[title='Zu wenig Praxis']")
  end

  it "shows nothing if not assessed" do
    participation.update_columns(qualified: nil, qualification_comment: "Notiz")

    expect(dom).not_to have_content "Bestanden"
    expect(dom).not_to have_css("i[title]")
  end

  context "with comments disabled" do
    before do
      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("event.qualifications.comments").and_return(false)
    end

    it "shows failed without tooltip" do
      participation.update_columns(qualified: false, qualification_comment: "Zu wenig Praxis")

      expect(dom).to have_content "Nicht bestanden"
      expect(dom).not_to have_css("i[title]")
    end

    it "shows failed if not assessed" do
      participation.update_column(:qualified, nil)

      expect(dom).to have_content "Nicht bestanden"
    end
  end
end
