require "spec_helper"

RSpec.describe Event::ParticipationFilter::List, type: :domain do
  subject { Event::ParticipationFilter::List.new(event, people(:bottom_member), params) }

  let(:leader) { event_participations(:top) }
  let(:event) { leader.event }
  let!(:participant) { Event::Participation.create(event: event, active: true, participant: person) }
  let(:person) { Fabricate(:person, first_name: "Max", last_name: "muster", nickname: "bambi") }
  let(:params) { {filters: {participant_type: "all"}} }

  before do
    Event::Course::Role::Participant.create(participation: participant)
  end

  context "without search string" do
    it "lists all entries" do
      expect(subject.list_entries.length).to eq(2)
    end
  end

  context "filter teamers" do
    let(:params) { {filters: {participant_type: "teamers"}} }

    it "lists only teamers" do
      expect(subject.list_entries).to eq [leader]
    end
  end

  context "filter participants" do
    let(:params) { {filters: {participant_type: "participants"}} }

    it "lists only participants" do
      expect(subject.list_entries).to eq [participant]
    end
  end

  context "search for first_name" do
    let(:params) { {filters: {participant_type: "all"}, q: "max"} }

    it "and list matching entries" do
      participants = subject.list_entries
      expect(participants.length).to eq(1)
      expect(participants.first.person).to eq(person)
    end
  end

  context "search for last_name" do
    let(:params) { {filters: {participant_type: "all"}, q: "ember"} }

    it "and list matching entries" do
      participants = subject.list_entries
      expect(participants.length).to eq(1)
      expect(participants.first.person).to eq(people(:bottom_member))
    end
  end

  context "search for nickname" do
    let(:params) { {filters: {participant_type: "all"}, q: "bambi"} }

    it "and list matching entries" do
      participants = subject.list_entries
      expect(participants.length).to eq(1)
      expect(participants.first.person).to eq(person)
    end
  end
end
