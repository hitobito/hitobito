# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextSearchable do
  it "finds Person by first name" do
    expect(Person.search("Top")).to eq [people(:top_leader)]
  end

  it "finds Person by part of first name" do
    expect(Person.search("To")).to eq [people(:top_leader)]
  end

  describe "special characters" do
    ["(", ")", ":", "&", "|", "!"].each do |char|
      it "ignores special character #{char}" do
        expect(Person.search("T#{char}op")).to eq [people(:top_leader)]
      end
    end

    it "ignores a c(o)mbination of invalid characters " do
      expect(Person.search("T(o)p")).to eq [people(:top_leader)]
    end
  end
end
