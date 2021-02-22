#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::Events::List do
  let(:course) { Fabricate(:course, groups: [groups(:top_group)], location: "somewhere", state: "somestate") }
  let(:courses) { [course] }
  let(:list) { Export::Tabular::Events::List.new(courses) }
  let(:csv) { Export::Csv::Generator.new(list).call.split("\n") }

  context "headers" do
    subject { csv.first }

    it { is_expected.to match(/^Name;Organisatoren;Kursnummer;Kursart;.*Anzahl Anmeldungen$/) }
  end

  context "first row" do
    subject { csv.second.split(";") }

    its([1]) { is_expected.to eq "TopGroup" }

    its([5]) { is_expected.to eq "somestate" }

    its([6]) { is_expected.to eq "somewhere" }

    context "state" do
      # This tests the case where Event.possible_states is empty,
      # the case with predefined states is tested in the jubla wagon.

      context "present" do
        its([5]) { is_expected.to eq "somestate" }
      end

      context "empty" do
        let(:course) do
          Fabricate(:course, groups: [groups(:top_group)], location: "somewhere")
        end
        let(:list) { Export::Tabular::Events::List.new([course]) }
        let(:csv) { Export::Csv::Generator.new(list).call.split("\n") }

        subject { csv.second.split(";") }

        its([5]) { is_expected.to eq "" }
      end
    end

    context "dates" do
      let(:start_at) { Date.parse "Sun, 09 Jun 2013" }
      let(:finish_at) { Date.parse "Wed, 12 Jun 2013" }
      let(:date) { Fabricate(:event_date, event: course, start_at: start_at, finish_at: finish_at, location: "somewhere") }

      before { allow(course).to receive(:dates).and_return([date]) }

      its([7]) { is_expected.to eq "Hauptanlass" }
      its([8]) { is_expected.to eq "somewhere" }
      its([9]) { is_expected.to eq "09.06.2013 - 12.06.2013" }
      its([10]) { is_expected.to eq "" }
    end

    context "contact" do
      let(:person) { Fabricate(:person_with_address_and_phone) }

      before { course.contact = person }

      its([16]) { is_expected.to eq person.to_s }
      its([21]) { is_expected.to eq person.phone_numbers.first.to_s }
      its([21]) { is_expected.to_not eq "" }
    end

    context "leader" do
      let(:participation) { Fabricate(:event_participation, event: course) }
      let!(:leader) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation).person }

      its([22]) { is_expected.to_not eq "" }
      its([22]) { is_expected.to eq leader.to_s }
    end
  end

  context "additional course labels" do
    let(:courses) { [course1, course2] }
    let(:course1) do
      Fabricate(:course, groups: [groups(:top_group)], motto: "All for one", cost: 1000,
                         application_opening_at: "01.01.2000", application_closing_at: "01.02.2000",
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

    context "first row" do
      let(:row) { csv[0].split(";") }

      it "should contain contain the additional course fields" do
        expect(row[28..-1]).to eq ["Motto", "Kosten", "Anmeldebeginn", "Anmeldeschluss",
                                   "Maximale Teilnehmerzahl", "Externe Anmeldungen",
                                   "Priorisierung", "Anzahl Leitungsteam", "Anzahl Teilnehmende",
                                   "Anzahl Anmeldungen",]
      end
    end

    context "second row" do
      let(:row) { csv[1].split(";") }

      it "should contain contain the additional course and record fields" do
        expect(row[28..-1]).to eq ["All for one", "1000", "01.01.2000", "01.02.2000", "10",
                                   "nein", "nein", "1", "1", "2",]
      end
    end

    context "third row (course without record)" do
      let(:row) { csv[2].split(";") }

      it "should contain the additional course fields" do
        expect(row[28..-1]).to eq ["", "", "", "", "", "nein", "ja", "0", "0", "0"]
      end
    end
  end

  context "multiple courses" do
    let(:course) { Fabricate(:course) }
    let(:courses) { [course, course, course, course] }

    subject { Export::Csv::Generator.new(list).call.split("\n") }

    it "has 5 rows" do
      expect(subject.size).to eq(5)
    end
  end
end
