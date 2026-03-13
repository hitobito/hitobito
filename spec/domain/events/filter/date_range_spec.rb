# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::DateRange do
  let(:base_scope) { Event.joins(:dates).distinct }

  subject(:filter) { described_class.new(:date_range, params) }

  def a_year_after(date)
    Date.parse(date).advance(years: 1)
  end

  let!(:event_in_range) do
    dates = [Fabricate.build(:event_date, start_at: "01.06.2020", finish_at: "15.06.2020")]
    Fabricate(:course, dates: dates)
  end

  let!(:event_before_range) do
    dates = [Fabricate.build(:event_date, start_at: "01.01.2019", finish_at: "15.01.2019")]
    Fabricate(:course, dates: dates)
  end

  let!(:event_after_range) do
    dates = [Fabricate.build(:event_date, start_at: "01.01.2025", finish_at: "15.01.2025")]
    Fabricate(:course, dates: dates)
  end

  let!(:event_overlapping_start) do
    dates = [Fabricate.build(:event_date, start_at: "15.12.2019", finish_at: "15.06.2020")]
    Fabricate(:course, dates: dates)
  end

  let!(:event_overlapping_end) do
    dates = [Fabricate.build(:event_date, start_at: "01.06.2020", finish_at: "15.2.2021")]
    Fabricate(:course, dates: dates)
  end

  context "with both since and until dates" do
    let(:params) do
      {
        since: "01.01.2020",
        until: "31.12.2020"
      }
    end

    it "includes events completely within the range" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(3)
      expect(result).to include(event_in_range)
      expect(result).to include(event_overlapping_start)
      expect(result).to include(event_overlapping_end)
      expect(result).not_to include(event_before_range)
      expect(result).not_to include(event_after_range)
    end
  end

  context "without dates" do
    let(:params) { {} }

    it "includes all events" do
      result = filter.apply(base_scope)
      expect(result.count).to eq 7
    end
  end

  context "with only a since date" do
    let(:params) { {since: "01.01.2020"} }

    it "includes events after since date" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(4)
      expect(result).to include(event_in_range)
      expect(result).to include(event_overlapping_start)
      expect(result).to include(event_overlapping_end)
      expect(result).to include(event_after_range)
    end
  end

  context "with only an until date" do
    let(:params) { {until: "31.12.2020"} }

    it "includes events before until date" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(6)
      expect(result).to include(event_in_range)
      expect(result).to include(event_overlapping_start)
      expect(result).to include(event_overlapping_end)
      expect(result).to include(event_before_range)
      expect(result).to include(events(:top_course))
      expect(result).to include(events(:top_event))
    end
  end
end
