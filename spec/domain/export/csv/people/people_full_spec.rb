# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:top_leader) }
  let(:scope) { Person.where(id: person.id) }
  let(:data) { Export::Tabular::People::PeopleFull.export(:csv, scope) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  before do
    PeopleRelation.kind_opposites["parent"] = "child"
    PeopleRelation.kind_opposites["child"] = "parent"
    person.update_attribute(:gender, "m")
    person.social_accounts << SocialAccount.new(label: "skype", name: "foobar")
    person.phone_numbers << PhoneNumber.new(label: "vater", number: "0791234567", public: false)
    person.additional_emails << AdditionalEmail.new(label: "vater", email: "vater@example.com",
      public: false)
    person.relations_to_tails << PeopleRelation.new(tail_id: people(:bottom_member).id,
      kind: "parent")
    person.save!
    I18n.locale = lang
  end

  after do
    I18n.locale = I18n.default_locale
    PeopleRelation.kind_opposites.clear
  end

  context "german" do
    let(:lang) { :de }

    it "has correct headers" do
      expected = [
        "Vorname", "Nachname", "Firmenname", "Übername", "Firma", "Haupt-E-Mail",
        "PLZ", "Ort", "Land",
        "Geschlecht", "Geburtstag", "Zusätzliche Angaben", "Sprache",
        "Strasse", "Hausnummer", "zusätzliche Adresszeile", "Postfach",
        "Hauptebene", "Rollen",
        "Tags", "Weitere E-Mail Vater", "Telefonnummer Vater", "Social Media Adresse Skype",
        "Elternteil"
      ]

      expect(csv.headers).to match_array expected
      expect(csv.headers).to eq expected
    end

    context "first row" do
      subject { csv[0] }

      its(["Rollen"]) { should eq "Leader Top / TopGroup" }
      its(["Telefonnummer Vater"]) { should eq "'+41 79 123 45 67" }
      its(["Weitere E-Mail Vater"]) { should eq "vater@example.com" }
      its(["Social Media Adresse Skype"]) { should eq "foobar" }
      its(["Elternteil"]) { should eq "Bottom Member" }
      its(["Geschlecht"]) { should eq "männlich" }
      its(["Hauptebene"]) { should eq "Top" }
    end
  end

  context "french" do
    let(:lang) { :fr }

    it "has correct headers" do
      headers = [
        "Prénom",
        "Nom",
        "Nom de l'entreprise",
        "Surnom",
        "Entreprise",
        "Adresse e-mail principale",
        "NPA",
        "Lieu",
        "Pays",
        "Sexe",
        "Date de naissance",
        "Données supplémentaires",
        "Langue",
        "Rue",
        "Numéro de la maison",
        "ligne d'adresse supplémentaire",
        "Case postale",
        "Niveau",
        "Rôles",
        "Tags",
        "Adresse e-mail supplémentaire Père",
        "Numéro de téléphone Père",
        "Adresse d'un média social Skype",
        "Parent"
      ]
      expect(csv.headers).to match_array headers
      expect(csv.headers).to eq headers
    end

    context "first row" do
      subject { csv[0] }

      its(["Rôles"]) { should eq "Leadre Top / TopGroup" }
      its(["Numéro de téléphone Père"]) { should eq "'+41 79 123 45 67" }
      its(["Adresse e-mail supplémentaire Père"]) { should eq "vater@example.com" }
      its(["Adresse d'un média social Skype"]) { should eq "foobar" }
      its(["Parent"]) { should eq "Bottom Member" }
      its(["Sexe"]) { should eq "masculin" }
    end
  end
end
