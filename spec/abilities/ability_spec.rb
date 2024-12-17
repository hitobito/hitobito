# frozen_string_literal: true

require "spec_helper"

describe Ability do
  subject { ability }

  let(:user) { people(:top_leader) }

  let(:ability) { described_class.new(user) }

  it "has unique identifier" do
    expect(ability.identifier).to eq "user-#{user.id}"
  end
end
