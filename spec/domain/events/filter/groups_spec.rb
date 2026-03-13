# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::Groups do
  let(:base_scope) { Event.all }
  subject(:filter) { described_class.new(:groups, params) }

  let(:user) { people(:top_leader) }
  let(:bottom_group) { groups(:bottom_layer_one) }
  let(:bottom_group_two) { groups(:bottom_layer_two) }
  let(:top_group) { groups(:top_layer) }

  let!(:course_in_bottom) do
    Fabricate(:course, groups: [bottom_group])
  end

  let!(:course_in_bottom_two) do
    Fabricate(:course, groups: [bottom_group_two])
  end

  let!(:course_in_top) do
    Fabricate(:course, groups: [top_group])
  end

  context "with the legitimate request to show courses in one group" do
    let(:params) { {ids: [bottom_group.id]} }

    it "shows only 1 result" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(1)
      expect(result).to include(course_in_bottom)
    end
  end

  context "with the legitimate request to show courses in multiple groups" do
    let(:params) { {ids: [bottom_group.id, bottom_group_two.id]} }

    it "shows only 2 result" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(2)
      expect(result).to include(course_in_bottom)
      expect(result).to include(course_in_bottom_two)
    end
  end
end
