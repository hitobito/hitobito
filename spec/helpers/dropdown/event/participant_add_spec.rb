require "spec_helper"

describe Dropdown::Event::ParticipantAdd do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:current_user) { people(:top_leader) }
  let(:event) { events(:top_event) }
  let(:group) { groups(:top_group) }
  let(:dropdown) do
    described_class.new(self, group, event, "Registrieren")
  end

  subject { Capybara.string(dropdown.to_s) }

  it "renders button" do
    is_expected.to have_content "Registrieren"
    is_expected.to_not have_css("ul.dropdown-menu li")
  end

  context ".for_user" do
    let(:dropdown) { described_class.for_user(self, group, event, current_user) }

    it "renders button" do
      is_expected.to have_content "Anmelden"
    end

    it "renders disabled button for participant" do
      Event::Participation.create!(event: event, participant: current_user)
      is_expected.to have_content "Angemeldet"
    end
  end

  context "with feature people_managers active" do
    before do
      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(true)
    end

    it "renders button" do
      is_expected.to have_content "Registrieren"
      is_expected.to_not have_css("ul.dropdown-menu li")
    end

    context "when user is a manager" do
      let(:bottom_member) { people(:bottom_member) }

      before do
        current_user.manageds = [bottom_member]
        current_user.save!
      end

      it "renders dropdown with correct links" do
        is_expected.to have_content "Registrieren"
        is_expected.to have_css("ul.dropdown-menu li", count: 2)
        is_expected.to have_link("Top Leader", href: contact_data_group_event_participations_path(
          group,
          event,
          event_role: {type: "Event::Role::Participant"}
        ))
        is_expected.to have_link("Bottom Member", href: contact_data_group_event_participations_path(
          group,
          event,
          {
            event_role: {type: "Event::Role::Participant"},
            person_id: bottom_member.id
          }
        ))
      end

      context ".for_user" do
        let(:dropdown) { described_class.for_user(self, group, event, current_user) }

        it "renders button for participant" do
          Event::Participation.create!(event: event, participant: current_user)
          is_expected.to have_content "Anmelden"
        end
      end
    end
  end
end
