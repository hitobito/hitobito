# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::FullText do
  let(:base_scope) { Event.all.joins(:translations) }

  subject(:filter) { described_class.new(:full_text, params) }

  let!(:bundstock) do
    Fabricate(:course, name: "Bundstock")
  end

  let!(:stockhorn) do
    Fabricate(:course, name: "Stockhorn", description: "Ein Bund Zwiebeln")
  end

  let!(:niederhorn) do
    Fabricate(:course, name: "Niederhorn")
  end

  context "with a possible match" do
    let(:params) do
      {q: "bund"}
    end

    it "includes only events with matching content" do
      result = filter.apply(base_scope)
      expect(result).to match_array([bundstock, stockhorn])
    end
  end
end
