# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::Groups::List do
  let(:group) { groups(:bottom_layer_one) }

  let(:list) { group.self_and_descendants.without_deleted.includes(:contact) }
  let(:data) { Export::Tabular::Groups::List.csv(list) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    expected = [
      "Id",
      "Elterngruppe",
      "Name",
      "Kurzname",
      "Gruppentyp",
      "Haupt-E-Mail",
      "PLZ",
      "Ort",
      "Land",
      "Geändert",
      "Ebene",
      "Beschreibung",
      "Link zu Nextcloud",
      "Strasse",
      "Hausnummer",
      "zusätzliche Adresszeile",
      "Postfach",
      "Telefonnummern",
      "Anzahl Mitglieder",
      "Social Media"
    ]

    should match_array expected
    should eq expected
  end

  it "has 4 items" do
    expect(subject.size).to eq(4)
  end

  context "first row with contact" do
    let(:contact) { people(:bottom_member) }

    subject { csv[0] }

    its(["Id"]) { should == group.id.to_s }
    its(["Elterngruppe"]) { should == group.parent_id.to_s }
    its(["Name"]) { should == group.name }
    its(["Kurzname"]) { should == group.short_name }
    its(["Gruppentyp"]) { should == "Bottom Layer" }
    its(["Haupt-E-Mail"]) { should == group.email }
    its(["Strasse"]) { should == contact.street }
    its(["Hausnummer"]) { should == contact.housenumber }
    its(["PLZ"]) { should == contact.zip_code.to_s }
    its(["Ort"]) { should == contact.town }
    its(["Land"]) { should == contact.country_label }
    its(["Ebene"]) { should == group.id.to_s }
    its(["Geändert"]) do
      should == "#{I18n.l(group.updated_at.to_date)} #{I18n.l(group.updated_at, format: :time)}"
    end
    its(["Anzahl Mitglieder"]) { should == "1" }
    its(["Telefonnummern"]) { should == "" }
    its(["Social Media"]) { should == "" }
  end

  context "second row" do
    let(:second_group) { groups(:bottom_group_one_one) }

    subject { csv[1] }

    its(["Elterngruppe"]) { should == group.id.to_s }
    its(["Ebene"]) { should == group.id.to_s }
    its(["Haupt-E-Mail"]) { should == second_group.email }
    its(["Strasse"]) { should == second_group.street }
    its(["Hausnummer"]) { should == second_group.housenumber }
    its(["PLZ"]) { should == second_group.zip_code.to_s }
    its(["Ort"]) { should == second_group.town }
    its(["Land"]) { should == second_group.country_label }
  end
end
