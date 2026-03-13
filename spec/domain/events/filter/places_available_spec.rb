# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::PlacesAvailable do
  let(:base_scope) { Event.all }
  subject(:filter) { described_class.new(:places_available, params) }

  let!(:unlimited_course) do
    Fabricate(:course, maximum_participants: nil, participant_count: 0)
  end

  let!(:filled_course) do
    Fabricate(:course, maximum_participants: 10, participant_count: 10)
  end

  let!(:available_course) do
    Fabricate(:course, maximum_participants: 10, participant_count: 5)
  end

  let!(:empty_course) do
    Fabricate(:course, maximum_participants: 10, participant_count: 0)
  end

  context "with the request to show available places" do
    let(:params) { {value: 1} }

    it "is not blank" do
      expect(filter.blank?).to be false
    end

    it "returns courses with available places" do
      result = filter.apply(base_scope)
      expect(result.count).to eq 5
      expect(result).to include(unlimited_course)
      expect(result).to include(available_course)
      expect(result).to include(empty_course)
      expect(result).not_to include(filled_course)
    end
  end

  context "with no request to limit to available places" do
    let(:params) { {} }

    it "is blank" do
      expect(filter.blank?).to be true
    end

    it "contains all events" do
      result = filter.apply(base_scope)
      expect(result.count).to eq 5
    end
  end
end
