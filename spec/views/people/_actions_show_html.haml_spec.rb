# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "people/_actions_show.html.haml" do
  let(:group) { person.primary_group }

  before do
    allow(controller).to receive(:current_user) { current_user }
    allow(view).to receive(:current_user) { current_user }
    allow(view).to receive(:entry) { person.decorate }
    allow(view).to receive(:parent) { group }
    allow(view).to receive(:path_args) { [group, person] }

    # skip dropdown_people_export, there is no test for it and it raises error with this setup
    allow(view).to receive(:dropdown_people_export)
    allow(view).to receive(:may_impersonate?)
  end

  def person_with_role(role_class, group)
    Fabricate(role_class.sti_name, group:).person
  end

  def current_user_finance_layer_ids
    controller.current_ability.user_finance_layer_ids
  end

  subject do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  describe "invoice button" do
    context "when user lacks finance permission" do
      let(:current_user) { person_with_role(Group::BottomGroup::Member, groups(:bottom_group_two_one)) }
      let(:person) { person_with_role(Group::BottomGroup::Leader, groups(:bottom_group_two_one)) }

      it "is not shown" do
        expect(current_user_finance_layer_ids).to be_empty
        is_expected.not_to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in same layer" do
      let(:current_user) { people(:bottom_member) } # has finance permission in bottom layer
      let(:person) { people(:bottom_member) }

      it "is shown" do
        expect(current_user_finance_layer_ids).to include(group.layer_group_id)
        is_expected.to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in upper layer" do
      let(:current_user) { people(:top_leader) }
      let(:person) { people(:bottom_member) }

      it "is shown" do
        expect(current_user_finance_layer_ids).to include(groups(:top_layer).id)
        is_expected.to have_link("Rechnung erstellen")
      end
    end

    context "when user has finance permission in sibling layer" do
      let(:current_user) { person_with_role(Group::BottomLayer::Member, groups(:bottom_layer_one)) }
      let(:person) { person_with_role(Group::BottomGroup::Member, groups(:bottom_group_two_one)) }

      it "is not shown" do
        expect(current_user_finance_layer_ids).to include(groups(:bottom_layer_one).id)
        is_expected.not_to have_link("Rechnung erstellen")
      end
    end
  end
end
