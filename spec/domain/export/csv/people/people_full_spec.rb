# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
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
    person.update_attribute(:gender, "m")
    person.social_accounts << SocialAccount.new(
      category: contact_account_categories(:social_account_person_facebook), name: "foobar"
    )
    person.phone_numbers << PhoneNumber.new(
      category: contact_account_categories(:phone_number_person_work), number: "0791234567", public: false
    )
    person.additional_emails << AdditionalEmail.new(
      category: contact_account_categories(:additional_email_person_work), email: "vater@example.com", public: false
    )
    person.save!
    I18n.locale = lang
  end

  after do
    I18n.locale = I18n.default_locale
  end

  context "german" do
    let(:lang) { :de }

    it "has correct headers" do
      expected = [
        "Vorname", "Nachname", "Übername", "Firmenname", "Firma", "Haupt-E-Mail",
        "zusätzliche Adresszeile", "Strasse", "Hausnummer", "Postfach", "PLZ", "Ort", "Land",
        "Hauptebene", "Rollen",
        "Geschlecht", "Geburtstag", "Zusätzliche Angaben", "Sprache", "Tags",
        "Weitere E-Mail Privat", "Weitere E-Mail Arbeit", "Weitere E-Mail Rechnungsadresse", "Weitere E-Mail Andere",
        "Telefonnummer Mobil", "Telefonnummer Festnetz", "Telefonnummer Arbeit", "Telefonnummer Andere",
        "Social Media Adresse Facebook", "Social Media Adresse X (Twitter)", "Social Media Adresse Webseite",
        "Social Media Adresse Andere"
      ]

      expect(csv.headers).to match_array expected
      expect(csv.headers).to eq expected
    end

    context "first row" do
      subject { csv[0] }

      its(["Rollen"]) { should eq "Leader Top / TopGroup" }
      its(["Telefonnummer Arbeit"]) { should eq "'+41 79 123 45 67" }
      its(["Weitere E-Mail Arbeit"]) { should eq "vater@example.com" }
      its(["Social Media Adresse Facebook"]) { should eq "foobar" }
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
        "Surnom",
        "Nom de l'entreprise",
        "Entreprise",
        "Adresse e-mail principale",
        "ligne d'adresse supplémentaire",
        "Rue",
        "Numéro de la maison",
        "Case postale",
        "NPA",
        "Lieu",
        "Pays",
        "Niveau",
        "Rôles",
        "Sexe",
        "Date de naissance",
        "Données supplémentaires",
        "Langue",
        "Tags",
        "Adresse e-mail supplémentaire Privé",
        "Adresse e-mail supplémentaire Professionnel",
        "Adresse e-mail supplémentaire Adresse de facturation",
        "Adresse e-mail supplémentaire Autre",
        "Numéro de téléphone Mobile",
        "Numéro de téléphone Ligne fixe",
        "Numéro de téléphone Professionnel",
        "Numéro de téléphone Autre",
        "Adresse d'un média social Facebook",
        "Adresse d'un média social X (Twitter)",
        "Adresse d'un média social Site web",
        "Adresse d'un média social Autre"
      ]
      expect(csv.headers).to match_array headers
      expect(csv.headers).to eq headers
    end

    context "first row" do
      subject { csv[0] }

      its(["Rôles"]) { should eq "Leadre Top / TopGroup" }
      its(["Numéro de téléphone Professionnel"]) { should eq "'+41 79 123 45 67" }
      its(["Adresse e-mail supplémentaire Professionnel"]) { should eq "vater@example.com" }
      its(["Adresse d'un média social Facebook"]) { should eq "foobar" }
      its(["Sexe"]) { should eq "masculin" }
    end
  end
end
