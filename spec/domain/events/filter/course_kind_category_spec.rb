# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::CourseKindCategory do
  let(:base_scope) { Event.all }
  subject(:filter) { described_class.new(:course_kind_category, params) }

  let!(:category_sbk) do
    Fabricate(:event_kind_category, label: "SBK")
  end

  let!(:category_vk) do
    Fabricate(:event_kind_category, label: "VK")
  end

  let!(:course_sbk) do
    kind = Fabricate(:event_kind, kind_category: category_sbk)
    Fabricate(:course, kind: kind)
  end

  let!(:course_vk) do
    kind = Fabricate(:event_kind, kind_category: category_vk)
    Fabricate(:course, kind: kind)
  end

  let!(:course_no_category) do
    kind = Fabricate(:event_kind, kind_category: nil)
    Fabricate(:course, kind: kind)
  end

  context "with category filter" do
    let(:params) { {id: category_sbk.id.to_s} }

    it "includes only SBK courses" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(1)
      expect(result).to include(course_sbk)
      expect(result).not_to include(course_vk)
      expect(result).not_to include(course_no_category)
    end
  end

  context "with multiple categories" do
    let(:params) { {id: [category_sbk.id.to_s, category_vk.id.to_s]} }

    it "includes both SBK and VK courses" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(2)
      expect(result).to include(course_sbk)
      expect(result).to include(course_vk)
      expect(result).not_to include(course_no_category)
    end
  end

  context "without category filter" do
    let(:params) { {} }

    it "does not filter by category" do
      expect(filter).to be_blank
    end
  end

  context "with 0 category" do
    let(:params) { {id: 0} }

    it "does filter events without category" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(3) # fixture events have no category
      expect(result).to include(course_no_category)
      expect(result).not_to include(course_sbk)
      expect(result).not_to include(course_vk)
    end
  end
end
