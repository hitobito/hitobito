# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::CourseKind do
  let(:base_scope) { Event::Course.all }
  subject(:filter) { described_class.new(:course_kind, params) }

  let!(:kind_sbk) do
    Fabricate(:event_kind, label: "SBK")
  end

  let!(:kind_vk) do
    Fabricate(:event_kind, label: "VK")
  end

  let!(:course_sbk) do
    Fabricate(:course, kind: kind_sbk)
  end

  let!(:course_vk) do
    Fabricate(:course, kind: kind_vk)
  end

  context "with kind filter" do
    let(:params) { {id: kind_sbk.id.to_s} }

    it "includes only SBK courses" do
      result = filter.apply(base_scope)
      expect(result).to match_array([course_sbk])
    end
  end

  context "with multiple categories" do
    let(:params) { {id: [kind_sbk.id.to_s, kind_vk.id.to_s]} }

    it "includes both SBK and VK courses" do
      result = filter.apply(base_scope)
      expect(result).to match_array([course_sbk, course_vk])
    end
  end

  context "without kind filter" do
    let(:params) { {id: ""} }

    it "does not filter by kind" do
      expect(filter).to be_blank
    end
  end
end
