# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Households::MembersQuery do
  let(:current_user) { Fabricate.build(:person, id: 1) }

  describe "initialization" do
    it "succeeds with person person_id is passed as nil" do
      described_class.new(current_user, nil)
    end
  end
end
