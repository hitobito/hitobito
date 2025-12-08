# frozen_string_literal: true

require "spec_helper"

describe Ability do
  subject { ability }

  let(:user) { people(:top_leader) }

  let(:ability) { described_class.new(user) }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer_one) { groups(:bottom_layer_one) }
  let(:bottom_layer_two) { groups(:bottom_layer_two) }

  it "has unique identifier" do
    expect(ability.identifier).to eq "user-#{user.id}"
  end

  describe "#user_finance_layer_ids" do
    def stub_complete_finance_permission_on(role_type)
      allow_any_instance_of(role_type).to receive(:permissions).and_return([:complete_finance])
    end
    it "includes layers for which finance permission is set" do
      expect(ability.user_finance_layer_ids).to eq [groups(:top_layer).id]
    end

    it "includes self and sub layers if complete_finance permission is set" do
      stub_complete_finance_permission_on(Group::TopGroup::Leader)

      expect(ability.user_finance_layer_ids).to match_array([
        top_layer.id,
        bottom_layer_one.id,
        bottom_layer_two.id
      ])
    end

    context "sublayer" do
      let(:user) { Fabricate(:person) }

      it "includes self but excludes top layer" do
        Fabricate(Group::BottomLayer::LocalGuide.sti_name, group: bottom_layer_one, person: user)
        stub_complete_finance_permission_on(Group::BottomLayer::LocalGuide)
        expect(ability.user_finance_layer_ids).to match_array([
          bottom_layer_one.id
        ])
      end
    end

    context "root" do
      let(:user) { people(:root) }

      it "defines user_finance_layer_ids" do
        expect(ability.user_finance_layer_ids).to match_array([
          groups(:top_layer).id,
          groups(:bottom_layer_one).id,
          groups(:bottom_layer_two).id
        ])
      end
    end
  end
end
