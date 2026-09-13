# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Carddav::AddressBook do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  subject(:address_book) { described_class.new(top_leader) }

  describe "#people" do
    it "contains all people accessible to the user" do
      expect(address_book.people).to match_array [top_leader, bottom_member]
    end

    it "is limited to the people a restricted user may see" do
      expect(described_class.new(bottom_member).people).to eq [bottom_member]
    end

    it "preloads everything a vcard needs" do
      people = address_book.people.to_a

      expect do
        people.each do |person|
          person.updated_at
          person.phone_numbers.to_a
          person.additional_emails.to_a
        end
      end.not_to make.db_queries
    end
  end

  describe "#find" do
    it "returns an accessible person" do
      expect(address_book.find(bottom_member.id)).to eq bottom_member
    end

    it "returns nil for an inaccessible person" do
      expect(address_book.find(people(:root).id)).to be_nil
    end
  end

  describe "#name and #description" do
    it "name the configured application" do
      allow(Settings.application).to receive(:name).and_return("MiData")

      expect(address_book.name).to eq "MiData Kontakte"
      expect(address_book.description)
        .to eq "Alle Personen, die Top Leader in MiData sehen darf."
    end
  end

  describe "#ctag" do
    it "changes when an accessible person changes" do
      expect { bottom_member.update!(town: "Zürich") }
        .to change { described_class.new(top_leader).ctag }
    end

    it "changes when a person becomes accessible" do
      expect { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }
        .to change { described_class.new(top_leader).ctag }
    end

    it "stays the same without changes" do
      expect(described_class.new(top_leader).ctag).to eq described_class.new(top_leader).ctag
    end
  end
end
