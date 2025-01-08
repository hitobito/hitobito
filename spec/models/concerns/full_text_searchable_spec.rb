# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextSearchable do
  let(:top_leader) { people(:top_leader) }

  it "finds Person by first name" do
    expect(Person.search("Top")).to eq [top_leader]
  end

  it "finds Person by part of first name" do
    expect(Person.search("To")).to eq [top_leader]
  end

  describe "special characters" do
    ["(", ")", ":", "&", "|", "!", "'", "?", "%", "<"].each do |char|
      it "ignores special character #{char}" do
        expect(Person.search("T#{char}op")).to eq [top_leader]
      end

      it "ignores special character #{char} as single charcter as well" do
        expect(Person.search("Top #{char}")).to eq [top_leader]
      end
    end

    [",", "*", " ", "-", ">", "`", "#", "@", "$", "="].each do |char|
      it "treats special character #{char} as part of search string" do
        expect(Person.search("T#{char}op")).to be_empty
      end
    end

    it "ignores c(o)mbination of special characters" do
      expect(Person.search("T(o)p")).to eq [top_leader]
    end
  end
end
