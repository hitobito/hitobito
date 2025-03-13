# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::People::PeopleAddress do
  let(:person) { people(:top_leader) }
  let(:scope) { Person.where(id: person.id) }
  let(:people_list) { Export::Tabular::People::PeopleAddress.new(scope) }
  subject { people_list }

  let(:data) { Export::Tabular::People::PeopleAddress.export(:csv, scope) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  context "headers" do
    let(:simple_headers) do
      ["Vorname", "Nachname", "Übername", "Firmenname", "Firma", "Haupt-E-Mail",
        "zusätzliche Adresszeile", "Strasse", "Hausnummer", "Postfach", "PLZ", "Ort", "Land",
        "Hauptebene", "Rollen"]
    end

    subject { csv }

    it "are present and complete" do
      headers = subject.headers

      expect(headers).to match_array(simple_headers)
      expect(headers.join("\n")).to eql(simple_headers.join("\n"))
      expect(headers).to eql(simple_headers)
    end
  end

  context "first row" do
    subject { csv[0] }

    its(["Vorname"]) { should eq person.first_name }
    its(["Nachname"]) { should eq person.last_name }
    its(["Haupt-E-Mail"]) { should eq person.email }
    its(["Ort"]) { should eq person.town }
    its(["Hauptebene"]) { should eq "Top" }

    context "roles and phone number" do
      before do
        Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one), person: person)
        person.phone_numbers.create!(label: "vater", number: "+41 44 123 45 67")
        person.additional_emails.create!(label: "Vater", email: "vater@example.com")
        person.additional_emails.create!(label: "Mutter", email: "mutter@example.com", public: false)
      end

      its(["Telefonnummer Vater"]) { should eq "'+41 44 123 45 67" }
      its(["Weitere E-Mail Vater"]) { should eq "vater@example.com" }
      its(["Weitere E-Mail Mutter"]) { should be_nil }

      it "roles should be complete" do
        expect(subject["Rollen"].split(", ")).to match_array(["Member Bottom One / Group 11", "Leader Top / TopGroup"])
      end
    end
  end
end
