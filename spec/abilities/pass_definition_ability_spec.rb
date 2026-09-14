#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassDefinitionAbility do
  let(:user) { role.person }
  let(:group) { role.group }
  let(:pass_definition) { Fabricate(:pass_definition, owner: group) }

  subject { Ability.new(user.reload) }

  before do
    Passes::TemplateRegistry.register("default",
      pdf_class: "Object", pass_view_partial: "test", wallet_data_provider: "Object")
  end

  context "layer and below full" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context "in own group" do
      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may create pass definitions" do
        is_expected.to be_able_to(:create, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end

      it "may destroy pass definitions" do
        is_expected.to be_able_to(:destroy, pass_definition)
      end

      it "may index pass grants" do
        is_expected.to be_able_to(:index_pass_grants, pass_definition)
      end
    end

    context "in group in same layer" do
      let(:group) { groups(:top_layer) }

      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end

      it "may index pass grants" do
        is_expected.to be_able_to(:index_pass_grants, pass_definition)
      end
    end

    context "in group in lower layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "may not show pass definitions" do
        is_expected.not_to be_able_to(:show, pass_definition)
      end

      it "may not update pass definitions" do
        is_expected.not_to be_able_to(:update, pass_definition)
      end

      it "may not destroy pass definitions" do
        is_expected.not_to be_able_to(:destroy, pass_definition)
      end
    end
  end

  context "layer full" do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    context "in own group" do
      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may create pass definitions" do
        is_expected.to be_able_to(:create, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end

      it "may destroy pass definitions" do
        is_expected.to be_able_to(:destroy, pass_definition)
      end
    end

    context "in group in same layer" do
      let(:group) { groups(:top_layer) }

      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end
    end

    context "in group in lower layer" do
      let(:group) { groups(:bottom_layer_one) }

      it "may not show pass definitions" do
        is_expected.not_to be_able_to(:show, pass_definition)
      end

      it "may not update pass definitions" do
        is_expected.not_to be_able_to(:update, pass_definition)
      end
    end
  end

  context "group full" do
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

    context "in own group" do
      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may create pass definitions" do
        is_expected.to be_able_to(:create, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end

      it "may destroy pass definitions" do
        is_expected.to be_able_to(:destroy, pass_definition)
      end
    end

    context "in other group" do
      let(:group) { groups(:bottom_group_one_two) }

      it "may not show pass definitions" do
        is_expected.not_to be_able_to(:show, pass_definition)
      end

      it "may not update pass definitions" do
        is_expected.not_to be_able_to(:update, pass_definition)
      end
    end
  end

  context "group and below full" do
    let(:role) { Fabricate(Group::TopGroup::GroupManager.name.to_sym, group: groups(:top_group)) }

    context "in own group" do
      it "may show pass definitions" do
        is_expected.to be_able_to(:show, pass_definition)
      end

      it "may create pass definitions" do
        is_expected.to be_able_to(:create, pass_definition)
      end

      it "may update pass definitions" do
        is_expected.to be_able_to(:update, pass_definition)
      end

      it "may destroy pass definitions" do
        is_expected.to be_able_to(:destroy, pass_definition)
      end
    end

    context "in other group in same layer" do
      let(:group) { groups(:top_layer) }

      it "may not show pass definitions" do
        is_expected.not_to be_able_to(:show, pass_definition)
      end

      it "may not update pass definitions" do
        is_expected.not_to be_able_to(:update, pass_definition)
      end
    end
  end

  context "with deleted group" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it "may not update pass definitions on deleted group" do
      group.update_column(:deleted_at, Time.zone.now)
      is_expected.not_to be_able_to(:update, pass_definition)
    end

    it "may not destroy pass definitions on deleted group" do
      group.update_column(:deleted_at, Time.zone.now)
      is_expected.not_to be_able_to(:destroy, pass_definition)
    end
  end
end
