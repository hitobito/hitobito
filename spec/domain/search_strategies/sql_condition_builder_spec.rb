# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SearchStrategies::SqlConditionBuilder do
  def search(word)
    Person.where(described_class.new(word, %w[people.last_name]).search_conditions)
  end

  let!(:underscore) { Fabricate(:person, last_name: "Muster_Mann") }
  let!(:percent) { Fabricate(:person, last_name: "Muster%Mann") }
  let!(:plain) { Fabricate(:person, last_name: "MusterXMann") }

  it "finds people containing the word" do
    expect(search("sterXMa")).to match_array([plain])
  end

  it "treats underscore literally" do
    expect(search("r_M")).to match_array([underscore])
  end

  it "treats percent sign literally" do
    expect(search("r%M")).to match_array([percent])
  end
end
