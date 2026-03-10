# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextSearchable do
  let(:top_leader) { people(:top_leader) }

  before { top_leader.update!(first_name: "John", last_name: "Smith") }

  it "finds model by first name" do
    expect(Person.search("John")).to eq [top_leader]
  end

  it "finds model with Umlaut, even in other languages" do
    top_leader.update!(first_name: "Jöhn")

    expect(Person.search("John")).to eq [top_leader]
    expect(Person.search("Jöhn")).to eq [top_leader]

    LocaleSetter.with_locale(locale: :fr) do
      expect(Person.search("John")).to eq [top_leader]
      expect(Person.search("Jöhn")).to eq [top_leader]
    end
  end

  it "finds model by full email" do
    expect(Person.search("top_leader@example.com")).to eq [top_leader]
  end

  it "finds model by partial email" do
    expect(Person.search("top_leader@example.co")).to eq [top_leader]
    expect(Person.search("top_leader@example.c")).to eq [top_leader]
    expect(Person.search("top_leader@examp")).to eq [top_leader]
    expect(Person.search("top")).to eq [top_leader]
  end

  it "finds model by prefix of first name" do
    expect(Person.search("Jo")).to eq [top_leader]
  end

  it "ignores ordering of search terms" do
    expect(Person.search("John Smith")).to eq [top_leader]
    expect(Person.search("Smith John")).to eq [top_leader]
  end

  it "ignores stopwords depending on the language" do
    expect(Person.search("das Smith")).to eq [top_leader]
    expect(Person.search("the Smith")).to be_empty

    LocaleSetter.with_locale(locale: :en) do
      expect(Person.search("das Smith")).to be_empty
      expect(Person.search("the Smith")).to eq [top_leader]
    end
  end

  it "finds model by language-specific stemming" do
    # Default stemming works
    expect(Person.search("Smither")).to eq [top_leader]

    top_leader.update!(first_name: "matinois")
    LocaleSetter.with_locale(locale: :fr) do
      # Query is stemmed to "matin" in french
      expect(Person.search("matinée")).to eq [top_leader]
    end
    LocaleSetter.with_locale(locale: :de) do
      # Query is stemmed to "matiné" in german
      expect(Person.search("matinée")).to be_empty
    end
  end

  it "falls back to no stemming for unsupported languages" do
    LocaleSetter.with_locale(locale: :rm) do
      top_leader.update!(first_name: "matinois")
      expect(Person.search("matinée")).to be_empty
      expect(Person.search("matinos")).to be_empty
      expect(Person.search("matinois")).to eq [top_leader]
    end
  end

  it "ensures all search terms are present" do
    expect(Person.search("John Doe Smith")).to be_empty
  end

  it "supports OR in query" do
    expect(Person.search("John OR Doe")).to eq [top_leader]
  end

  it "supports excluding terms in query" do
    expect(Person.search("John -Smith")).to be_empty
    expect(Person.search("John -Doe")).to eq [top_leader]
  end

  it "ensures all search terms are present" do
    top_leader.update!(first_name: "John", last_name: "Smith")
    expect(Person.search("John Smith")).to eq [top_leader]
    expect(Person.search("John Doe Smith")).to be_empty
  end

  it "supports quoting multiple words" do
    top_leader.update!(first_name: "John", last_name: "Smith")
    expect(Person.search("\"John Smith\"")).to eq [top_leader]
    expect(Person.search("\"Smith John\"")).to be_empty
    expect(Person.search("Smith John")).to eq [top_leader]
  end

  describe "special characters" do
    ["(", ")", ":", "&", "|", "!", "'", "?", "%", "<", " ", " "].each do |char|
      it "treats special character #{char} like a space" do
        expect(Person.search("John#{char}Smith")).to eq [top_leader]
        expect(Person.search("J#{char}ohn")).to be_empty
      end

      it "ignores special character #{char}" do
        expect(Person.search("John#{char}")).to eq [top_leader]
      end

      it "ignores special character #{char} as single charcter as well" do
        expect(Person.search("John #{char}")).to eq [top_leader]
      end
    end
  end

  context "invoice search" do
    let(:group) { groups(:top_layer) }
    let!(:invoice) {
      Fabricate(:invoice, group:, title: "Testrechnung", invoice_items: [
        InvoiceItem.new(count: 1, unit_cost: 100, name_de: "Stifte", name_fr: "Crayons")
      ])
    }

    it "finds invoice by title" do
      expect(Invoice.search("Testrechnung")).to eq [invoice]
      expect(Invoice.search("Test")).to eq [invoice]
    end

    it "finds invoice by invoice item name" do
      expect(Invoice.search("Stif")).to eq [invoice]
    end

    it "finds invoice by invoice item name in other language" do
      expect(Invoice.search("Cray")).to eq [invoice]
    end
  end
end
