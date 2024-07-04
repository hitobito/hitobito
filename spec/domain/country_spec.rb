# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Country do
  context "#name" do
    it "returns country name for current locale" do
      country = Country.new("CH")
      expect(country.name).to eq "Schweiz"
    end

    it "returns country name for specified locale" do
      country = Country.new("CH")
      expect(country.name(:it)).to eq "Svizzera"
    end

    it "returns country code if country is not found" do
      country = Country.new("XX")
      expect(country.name).to eq "XX"
    end
  end
end
