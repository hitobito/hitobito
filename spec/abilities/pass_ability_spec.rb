# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PassAbility do
  let(:person) { people(:top_leader) }

  subject(:ability) { Ability.new(person) }

  context "herself" do
    it "may show own pass" do
      pass = Fabricate.build(:pass, person: person)
      is_expected.to be_able_to(:show, pass)
    end

    it "may not show another person's pass even with read permission on person" do
      other_person = people(:bottom_member)
      other_person_pass = Fabricate(:pass, person: other_person)

      is_expected.to be_able_to(:show, other_person)
      is_expected.not_to be_able_to(:show, other_person_pass)
    end
  end
end
