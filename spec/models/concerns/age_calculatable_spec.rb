# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AgeCalculatable do
  let(:test_model) do
    Struct.new(:birthday) do
      include AgeCalculatable
    end
  end

  before do
    travel_to Time.zone.local(2021, 5, 24)
  end

  it "is nil if person has no birthday" do
    expect(test_model.new(nil).years).to be_nil
  end

  [[Date.new(2006, 2, 12), 15], [Date.new(2005, 3, 15), 16], [Date.new(2004, 2, 29), 17]].each do |birthday, years|
    it "is #{years} years old if born on #{birthday}" do
      expect(test_model.new(birthday).years).to eq years
    end
  end

  it "allows passing a custom comparison date" do
    instance = test_model.new(Date.new(2000, 1, 1)) # 21 years old during our temporary stay in 2021
    comparison = Date.new(2010, 1, 1)

    expect(instance.years(comparison)).to eq(10)
  end
end
