# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe JsonApi::GroupAbility do
  let(:group) { groups(:top_group) }

  let(:main_ability) { Ability.new(user) }

  subject { JsonApi::GroupAbility.new(main_ability) }

  context "root user" do
    let(:user) { people(:root) }

    it "is able to read group" do
      is_expected.to be_able_to(:read, group)
    end

    it "is able to index groups" do
      is_expected.to be_able_to(:index, Group)
    end
  end
end
