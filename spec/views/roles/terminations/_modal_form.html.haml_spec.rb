# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "roles/terminations/_modal_form.html.haml" do
  before do
    allow(view).to receive(:role).and_return(role)
    allow(view).to receive(:entry).and_return(Roles::Termination.new(role: role))
  end

  subject { Capybara::Node::Simple.new(render) }

  context "for role with end_on set" do
    let(:end_on) { Time.zone.tomorrow }
    let(:role) { roles(:bottom_member).tap { |r| r.end_on = end_on } }

    it "shows end_on text" do
      expect(subject).not_to have_field("Austrittsdatum")
      expect(subject).to have_content "Austrittsdatum: #{end_on.strftime("%d.%m.%Y")}"
    end
  end

  context "for role with blank end_on" do
    let(:role) { roles(:bottom_member) }

    it "has end_on date field" do
      expect(subject).not_to have_content "Austrittsdatum:"
      expect(subject).to have_field("Austrittsdatum")
    end
  end
end
