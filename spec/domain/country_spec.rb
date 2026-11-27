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

  context "#postal_name" do
    it "uses the official language of neighbouring countries" do
      expect(%w[DE AT FR IT LI].map { |code| Country.new(code).postal_name })
        .to eq %w[DEUTSCHLAND ÖSTERREICH FRANCE ITALIA LIECHTENSTEIN]
    end

    it "uses english for other countries" do
      expect(Country.new("ES").postal_name).to eq "SPAIN"
    end

    it "does not depend on the current locale" do
      I18n.with_locale(:fr) { expect(Country.new("DE").postal_name).to eq "DEUTSCHLAND" }
    end

    it "returns country code if country is not found" do
      expect(Country.new("XX").postal_name).to eq "XX"
    end
  end
end
