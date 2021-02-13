# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Events::List do

  let(:courses) { double("courses", map: [], first: nil) }
  let(:list)  { Export::Tabular::Events::List.new(courses) }

  subject { list }

  its(:contactable_keys) { should eq [:name, :address, :zip_code, :town, :email, :phone_numbers] }

  context "used labels" do
    subject { list }

    its(:attributes) do
      should == [:name, :group_names, :number, :kind, :description, :state, :location,
                 :date_0_label, :date_0_location, :date_0_duration,
                 :date_1_label, :date_1_location, :date_1_duration,
                 :date_2_label, :date_2_location, :date_2_duration,
                 :contact_name, :contact_address, :contact_zip_code, :contact_town,
                 :contact_email, :contact_phone_numbers,
                 :leader_name, :leader_address, :leader_zip_code, :leader_town,
                 :leader_email, :leader_phone_numbers,
                 :motto, :cost, :application_opening_at, :application_closing_at,
                 :maximum_participants, :external_applications, :priorization,
                 :teamer_count, :participant_count, :applicant_count]
    end

    its(:labels) do
      should == ["Name", "Organisatoren", "Kursnummer", "Kursart", "Beschreibung", "Status", "Ort / Adresse",
                 "Datum 1 Bezeichnung", "Datum 1 Ort", "Datum 1 Zeitraum",
                 "Datum 2 Bezeichnung", "Datum 2 Ort", "Datum 2 Zeitraum",
                 "Datum 3 Bezeichnung", "Datum 3 Ort", "Datum 3 Zeitraum",
                 "Kontaktperson Name", "Kontaktperson Adresse", "Kontaktperson PLZ",
                 "Kontaktperson Ort", "Kontaktperson Haupt-E-Mail", "Kontaktperson Telefonnummern",
                 "Hauptleitung Name", "Hauptleitung Adresse", "Hauptleitung PLZ", "Hauptleitung Ort",
                 "Hauptleitung Haupt-E-Mail", "Hauptleitung Telefonnummern",
                 "Motto", "Kosten", "Anmeldebeginn", "Anmeldeschluss", "Maximale Teilnehmerzahl",
                 "Externe Anmeldungen", "Priorisierung", "Anzahl Leitungsteam",
                 "Anzahl Teilnehmende", "Anzahl Anmeldungen"]
    end
  end

end
