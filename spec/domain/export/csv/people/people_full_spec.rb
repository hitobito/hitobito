#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:data) { Export::Tabular::People::PeopleFull.export(:csv, list) }
  let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

  before do
    person.update_attribute(:gender, "m")
    person.social_accounts << SocialAccount.new(label: "skype", name: "foobar")
    person.phone_numbers << PhoneNumber.new(label: "vater", number: 123, public: false)
    person.additional_emails << AdditionalEmail.new(label: "vater", email: "vater@example.com", public: false)
    person.relations_to_tails << PeopleRelation.new(tail_id: people(:bottom_member).id, kind: "parent")
    person.save
    I18n.locale = lang
  end

  after do
    I18n.locale = I18n.default_locale
    PeopleRelation.kind_opposites.clear
  end

  context "german" do
    let(:lang) { :de }

    it "has correct headers" do
      expect(csv.headers).to eq([
        "Vorname", "Nachname", "Firmenname", "Übername", "Firma", "Haupt-E-Mail",
        "Adresse", "PLZ", "Ort", "Land", "Geschlecht", "Geburtstag",
        "Zusätzliche Angaben", "Hauptebene", "Rollen", "Tags", "Weitere E-Mail Vater",
        "Telefonnummer Vater", "Social Media Adresse Skype", "Elternteil",
      ])
    end

    context "first row" do
      subject { csv[0] }

      its(["Rollen"]) { is_expected.to eq "Leader Top / TopGroup" }
      its(["Telefonnummer Vater"]) { is_expected.to eq "123" }
      its(["Weitere E-Mail Vater"]) { is_expected.to eq "vater@example.com" }
      its(["Social Media Adresse Skype"]) { is_expected.to eq "foobar" }
      its(["Elternteil"]) { is_expected.to eq "Bottom Member" }
      its(["Geschlecht"]) { is_expected.to eq "männlich" }
      its(["Hauptebene"]) { is_expected.to eq "Top" }
    end
  end

  context "french" do
    let(:lang) { :fr }

    it "has correct headers" do
      expect(csv.headers).to eq(
        ["Prénom", "Nom", "Nom de l'entreprise", "Surnom", "Entreprise",
         "Adresse e-mail principale", "Adresse", "Code postal", "Lieu", "Pays", "Sexe",
         "Date de naissance", "Données supplémentaires", "Niveau", "Rôles", "Tags",
         "Adresse e-mail supplémentaire Père", "Numéro de téléphone Père",
         "Adresse d'un média social Skype", "Parent",]
      )
    end

    context "first row" do
      subject { csv[0] }

      its(["Rôles"]) { is_expected.to eq "Leadre Top / TopGroup" }
      its(["Numéro de téléphone Père"]) { is_expected.to eq "123" }
      its(["Adresse e-mail supplémentaire Père"]) { is_expected.to eq "vater@example.com" }
      its(["Adresse d'un média social Skype"]) { is_expected.to eq "foobar" }
      its(["Parent"]) { is_expected.to eq "Bottom Member" }
      its(["Sexe"]) { is_expected.to eq "Masculin" }
    end
  end
end
