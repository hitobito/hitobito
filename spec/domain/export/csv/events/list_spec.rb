# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Export::Csv::Events::List do

  let(:courses) { double('courses', map: [], first: nil) }
  let(:list)  { Export::Csv::Events::List.new(courses) }
  subject { list }

  its(:contactable_keys) { should eq [:name, :address, :zip_code, :town, :email, :phone_numbers] }

  context 'used labels' do
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
      should == ['Name', 'Organisatoren', 'Kursnummer', 'Kursart', 'Beschreibung', 'Status', 'Ort / Adresse',
                 'Datum 1 Beschreibung', 'Datum 1 Ort', 'Datum 1 Zeitraum',
                 'Datum 2 Beschreibung', 'Datum 2 Ort', 'Datum 2 Zeitraum',
                 'Datum 3 Beschreibung', 'Datum 3 Ort', 'Datum 3 Zeitraum',
                 'Kontaktperson Name', 'Kontaktperson Adresse', 'Kontaktperson PLZ',
                 'Kontaktperson Ort', 'Kontaktperson Haupt-E-Mail', 'Kontaktperson Telefonnummern',
                 'Hauptleitung Name', 'Hauptleitung Adresse', 'Hauptleitung PLZ', 'Hauptleitung Ort',
                 'Hauptleitung Haupt-E-Mail', 'Hauptleitung Telefonnummern',
                 'Motto', 'Kosten', 'Anmeldebeginn', 'Anmeldeschluss', 'Maximale Teilnehmerzahl',
                 'Externe Anmeldungen', 'Priorisierung', 'Anzahl Leitungsteam',
                 'Anzahl Teilnehmende', 'Anzahl Anmeldungen']
    end
  end


  context 'to_csv' do
    let(:courses) { [course] }
    let(:course) { Fabricate(:course, groups: [groups(:top_group)], location: 'somewhere', state: 'somestate')  }
    let(:csv) { Export::Csv::Generator.new(list).csv.split("\n")  }

    context 'headers' do
      subject { csv.first }
      it { should match(/^Name;Organisatoren;Kursnummer;Kursart;.*Anzahl Anmeldungen$/) }
    end

    context 'first row' do
      subject { csv.second.split(';') }
      its([1]) { should eq 'TopGroup' }


      its([5]) { should eq 'somestate' }

      its([6]) { should eq 'somewhere' }

      context 'state' do
        # This tests the case where Event.possible_states is empty,
        # the case with predefined states is tested in the jubla wagon.

        context 'present' do
          its([5]) { should eq 'somestate' }
        end

        context 'empty' do
          let(:course) do
            Fabricate(:course, groups: [groups(:top_group)], location: 'somewhere')
          end
          let(:list)  { Export::Csv::Events::List.new([course]) }
          let(:csv) { Export::Csv::Generator.new(list).csv.split("\n")  }
          subject { csv.second.split(';') }

          its([5]) { should eq '' }
        end
      end

      context 'dates' do
        let(:start_at) { Date.parse 'Sun, 09 Jun 2013' }
        let(:finish_at) { Date.parse 'Wed, 12 Jun 2013' }
        let(:date) { Fabricate(:event_date, event: course, start_at: start_at, finish_at: finish_at, location: 'somewhere') }

        before { course.stub(dates: [date]) }
        its([7]) { should eq 'Hauptanlass' }
        its([8]) { should eq 'somewhere' }
        its([9]) { should eq '09.06.2013 - 12.06.2013' }
        its([10]) { should eq '' }
      end

      context 'contact' do
        let(:person) { Fabricate(:person_with_address_and_phone) }
        before { course.contact = person }
        its([16]) { should eq person.to_s }
        its([21]) { should eq person.phone_numbers.first.to_s }
        its([21]) { should_not eq '' }
      end

      context 'leader' do
        let(:participation) { Fabricate(:event_participation, event: course) }
        let!(:leader) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation).person }
        its([22]) { should_not eq '' }
        its([22]) { should eq leader.to_s }
      end
    end

    context 'additional course labels' do
      let(:courses) { [course1, course2] }
      let(:course1) do
        Fabricate(:course, groups: [groups(:top_group)], motto: 'All for one', cost: 1000,
                  application_opening_at: '01.01.2000', application_closing_at: '01.02.2000',
                  maximum_participants: 10, external_applications: false, priorization: false)
      end
      let(:course2) { Fabricate(:course, groups: [groups(:top_group)]) }

      before do
        Fabricate(:event_participation, event: course1, active: true,
                  roles: [Fabricate(:event_role, type: Event::Role::Leader.sti_name)])
        Fabricate(:event_participation, event: course1, active: true,
                  roles: [Fabricate(:event_role, type: Event::Course::Role::Participant.sti_name)])
        Fabricate(:event_participation, event: course1, active: false,
                  roles: [Fabricate(:event_role, type: Event::Course::Role::Participant.sti_name)])
        course1.refresh_participant_counts!
        course2.refresh_participant_counts!
      end

      context 'first row' do
        let(:row) { csv[0].split(';') }
        it 'should contain contain the additional course fields' do
          expect(row[28..-1]).to eq ['Motto', 'Kosten', 'Anmeldebeginn', 'Anmeldeschluss',
                                     'Maximale Teilnehmerzahl', 'Externe Anmeldungen',
                                     'Priorisierung', 'Anzahl Leitungsteam', 'Anzahl Teilnehmende',
                                     'Anzahl Anmeldungen']
        end
      end

      context 'second row' do
        let(:row) { csv[1].split(';') }
        it 'should contain contain the additional course and record fields' do
          expect(row[28..-1]).to eq ['All for one', '1000', '2000-01-01', '2000-02-01', '10',
                                     'nein', 'nein', '1', '1', '2']
        end
      end

      context 'third row (course without record)' do
        let(:row) { csv[2].split(';') }
        it 'should contain the additional course fields' do
          expect(row[28..-1]).to eq ['', '', '', '', '', 'nein', 'ja', '0', '0', '0']
        end
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
