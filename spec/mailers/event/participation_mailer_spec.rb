# encoding: UTF-8
require "spec_helper"

describe Event::ParticipationMailer do
  describe "created" do
    let(:person) { people(:top_leader) }
    let(:event) { Fabricate(:event) }
    let(:participation) { Fabricate(:event_participation,event: event) }
    let(:mail) { Event::ParticipationMailer.confirmation(person, participation) }

    let(:participation_url) { event_participation_path(participation.event, participation)}

    it "renders the headers" do
      mail.subject.should eq "Bestätigung der Anmeldung"
      mail.to.should eq(["top_leader@example.com"])
      mail.from.should eq(["jubla@puzzle.ch"])
      mail
    end 



    describe "event data" do
      subject { mail.body }
      it "renders set attributes only" do
        should =~ /Name:\s+Eventus/
        should_not =~ /Kontaktperson:\s+Top Leader/
        should_not =~ /Daten/
      end

      it "renders location if set" do
        event.location = 'some location'
        should =~ /Ort \/ Adresse:\s+some location/
      end

      it "renders dates if set" do
        event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
        should =~ /Daten:\s+Vorweekend: 18.10.2012 - 21.10.2012/
      end

      it "renders multiple dates below each other" do
        event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
        event.dates.build(label: 'Kurs', start_at: Date.parse('2012-10-21'))
        should =~ /Daten:\s+Vorweekend: 18.10.2012 - 21.10.2012\n/
        should =~ /\s+Kurs: 21.10.2012\n/
      end
    end

  end
end
