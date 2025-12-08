# frozen_string_literal: true

require "spec_helper"

describe Ability do
  subject { ability }

  let(:user) { people(:top_leader) }

  let(:ability) { described_class.new(user) }

  it "has unique identifier" do
    expect(ability.identifier).to eq "user-#{user.id}"
  end

  describe "#user_finance_layer_ids" do
    it "includes layers for which finance permission is set" do
      expect(ability.user_finance_layer_ids).to eq [groups(:top_layer).id]
    end

    it "includes all layers if complete_finance permission is set" do
      allow_any_instance_of(Group::TopGroup::Leader).to receive(:permissions)
        .and_return([:complete_finance])

      expect(ability.user_finance_layer_ids).to match_array([
        groups(:top_layer).id,
        groups(:bottom_layer_one).id,
        groups(:bottom_layer_two).id
      ])
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
