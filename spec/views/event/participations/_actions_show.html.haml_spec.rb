#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participations/_actions_show.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:event) { Fabricate(:event, groups: [group]) }
  let(:participant) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, participant:, event:) }
  let(:user) { participant }

  before do
    CustomContent.create!(key: "event_application_confirmation", label: "Custom Content Label 1", body: "")
    CustomContent.create!(key: "event_application_approval", label: "Custom Content Label 2", body: "")
    allow(view).to receive_messages(path_args: [group, event])
    allow(view).to receive_messages(entry: participation)
    allow(controller).to receive(:current_user) { user }
    allow(view).to receive(:current_user) { user }
    controller.request.path_parameters[:action] = "show"
    controller.request.path_parameters[:group_id] = 42
    controller.request.path_parameters[:event_id] = 42
    controller.request.path_parameters[:id] = 42
    assign(:event, event)
    assign(:group, group)
  end

  context "second to last button is by default the change contact data button" do
    subject { Capybara::Node::Simple.new(raw(rendered)).all("a")[-2] }

    before { render }

    its([:href]) {
      should eq edit_group_person_path(user.groups.first, user, return_url: "/de/groups/42/events/42/participations/42")
    }
    its(:text) { should eq " Kontaktdaten ändern" } # space because of icon
  end

  context "last button is by default the show person profile button" do
    subject { Capybara::Node::Simple.new(raw(rendered)).all("a").last }

    before { render }

    its([:href]) { should eq group_person_path(user.groups.first, user) }
    its(:text) { should eq " Personenprofil anzeigen" } # space because of icon
  end

  context "invoice button" do
    def person_with_role(role_class, group)
      Fabricate(role_class.sti_name, group:).person
    end

    def user_finance_layer_ids
      controller.current_ability.user_finance_layer_ids
    end

    subject do
      render
      Capybara::Node::Simple.new(@rendered)
    end

    context "when user lacks finance permission" do
      let(:user) { person_with_role(Group::BottomLayer::Leader, event.groups.first) }
      let(:participant) { person_with_role(Group::BottomLayer::LocalGuide, event.groups.first) }

      it "is not shown" do
        expect(user_finance_layer_ids).to be_empty
        is_expected.not_to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in same layer" do
      let(:user) { person_with_role(Group::BottomLayer::Member, event.groups.first) }
      let(:participant) { person_with_role(Group::BottomLayer::LocalGuide, event.groups.first) }

      it "is shown" do
        expect(user_finance_layer_ids).to include(group.layer_group_id)
        is_expected.to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in upper layer" do
      let(:user) { people(:top_leader) }
      let(:participant) { person_with_role(Group::BottomLayer::LocalGuide, event.groups.first) }

      it "is shown" do
        expect(user_finance_layer_ids).to include(groups(:top_layer).id)
        is_expected.to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in sibling layer" do
      let(:user) { person_with_role(Group::BottomLayer::Member, groups(:bottom_layer_two)) }
      let(:participant) { person_with_role(Group::BottomLayer::LocalGuide, event.groups.first) }

      it "is not shown" do
        expect(user_finance_layer_ids).to include(groups(:bottom_layer_two).id)
        is_expected.not_to have_link("Rechnung erstellen")
      end
    end
  end
end
