# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe DoorkeeperTokenAbility do
  subject { ability }

  let(:user) { people(:top_leader) }

  let(:application) { Fabricate(:application, scopes: "openid") }
  let(:token) { Fabricate(:access_token, application: application, scopes: "openid", resource_owner_id: user.id) }

  let(:ability) { described_class.new(token) }

  it "has unique identifier" do
    expect(ability.identifier).to eq "user-#{user.id}"
  end
end
