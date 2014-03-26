# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Export::Csv::Events::List do

  let(:courses) { double('courses', map: []) }
  let(:list)  { Export::Csv::Events::List.new(courses) }
  subject { list }

  its(:contactable_keys) { should eq [:name, :address, :zip_code, :town, :email, :phone_numbers] }

  context 'used labels' do
    subject { list }

    its(:attributes) do
      should =~ [:group_names, :number, :kind, :description, :state, :location,
                 :date_0_label, :date_0_location, :date_0_duration,
                 :date_1_label, :date_1_location, :date_1_duration,
                 :date_2_label, :date_2_location, :date_2_duration,
                 :contact_name, :contact_address, :contact_zip_code, :contact_town,
                 :contact_email, :contact_phone_numbers,
                 :leader_name, :leader_address, :leader_zip_code, :leader_town,
                 :leader_email, :leader_phone_numbers]
    end

    its(:labels) do
      should =~ ['Organisatoren', 'Kursnummer', 'Kursart', 'Beschreibung', 'Status', 'Ort / Adresse',
                 'Datum 1 Beschreibung', 'Datum 1 Ort', 'Datum 1 Zeitraum',
                 'Datum 2 Beschreibung', 'Datum 2 Ort', 'Datum 2 Zeitraum',
                 'Datum 3 Beschreibung', 'Datum 3 Ort', 'Datum 3 Zeitraum',
                 'Kontaktperson Name', 'Kontaktperson Adresse', 'Kontaktperson PLZ',
                 'Kontaktperson Ort', 'Kontaktperson Haupt-E-Mail', 'Kontaktperson Telefonnummern',
                 'Hauptleitung Name', 'Hauptleitung Adresse', 'Hauptleitung PLZ', 'Hauptleitung Ort',
                 'Hauptleitung Haupt-E-Mail', 'Hauptleitung Telefonnummern']
    end
  end


  context 'to_csv' do
    let(:courses) { [course] }
    let(:course) { Fabricate(:course, groups: [groups(:top_group)], location: 'somewhere', state: 'somestate')  }
    let(:csv) { Export::Csv::Generator.new(list).csv.split("\n")  }

    context 'headers' do
      subject { csv.first }
      it { should match(/^Organisatoren;Kursnummer;Kursart;.*Hauptleitung Telefonnummern$/) }
    end

    context 'first row' do
      subject { csv.second.split(';') }
      its([0]) { should eq 'TopGroup' }
      its([4]) { should =~ /translation missing/ }
      its([4]) { should =~ /somestate/ }
      its([5]) { should eq 'somewhere' }

      context 'dates' do
        let(:start_at) { Date.parse 'Sun, 09 Jun 2013' }
        let(:finish_at) { Date.parse 'Wed, 12 Jun 2013' }
        let(:date) { Fabricate(:event_date, event: course, start_at: start_at, finish_at: finish_at, location: 'somewhere') }

        before { course.stub(dates: [date]) }
        its([6]) { should eq 'Hauptanlass' }
        its([7]) { should eq 'somewhere' }
        its([8]) { should eq '09.06.2013 - 12.06.2013' }
        its([9]) { should eq nil }
      end

      context 'contact' do
        let(:person) { Fabricate(:person_with_address_and_phone) }
        before { course.contact = person }
        its([15]) { should eq person.to_s }
        its([20]) { should eq person.phone_numbers.first.to_s }
        its([20]) { should_not eq '' }
      end

      context 'leader' do
        let(:participation) { Fabricate(:event_participation, event: course) }
        let!(:leader) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation).person }
        its([21]) { should_not eq '' }
        its([21]) { should eq leader.to_s }
      end
    end
  end

  context 'multiple courses' do
    let(:course) { Fabricate(:course) }
    let(:courses) { [course, course, course, course] }
    subject { Export::Csv::Generator.new(list).csv.split("\n") }
    it { should have(5).rows }
  end


end
