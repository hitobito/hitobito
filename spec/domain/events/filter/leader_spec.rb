# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::Leader do
  let(:base_scope) { Event::Course.all }

  subject(:filter) { described_class.new(:leader, params) }

  let(:kurs1) { Fabricate(:course) }
  let(:kurs2) { Fabricate(:course) }
  let(:kurs3) { Fabricate(:course) }
  let(:kurs4) { Fabricate(:course) }

  let!(:kurs1_leader) do
    p1 = Fabricate(:event_participation, event: kurs1)
    Event::Role::Leader.create!(participation: p1)
    p2 = Fabricate(:event_participation, event: kurs4, participant: p1.person)
    Event::Role::Cook.create!(participation: p2)

    p1.person
  end

  let!(:kurs2_leader) do
    p = Fabricate(:event_participation, event: kurs2)
    Event::Role::Leader.create!(participation: p)
    p.person
  end

  let!(:kurs3_leader) do
    p = Fabricate(:event_participation, event: kurs3)
    Event::Role::Leader.create!(participation: p)
    p.person
  end

  context "with a possible match" do
    let(:params) do
      {ids: kurs1_leader.id}
    end

    it "includes only events with matching content" do
      result = filter.apply(base_scope)
      expect(result).to match_array([kurs1])
    end
  end

  context "with only user" do
    let(:params) do
      {user: "1"}
    end

    it "includes only events with matching content" do
      Auth.current_person = kurs3_leader
      result = filter.apply(base_scope)
      expect(result).to match_array([kurs3])
    end
  end

  context "with user and id" do
    let(:params) do
      {ids: [kurs1_leader.id, 42], user: "1"}
    end

    it "includes only events with matching content" do
      Auth.current_person = kurs3_leader
      result = filter.apply(base_scope)
      expect(result).to match_array([kurs1, kurs3])
    end
  end
end
