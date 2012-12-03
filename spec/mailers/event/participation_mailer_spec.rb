# encoding: UTF-8
require "spec_helper"

describe Event::ParticipationMailer do
  
  before(:each) do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end
  
  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event) }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }
  
  subject { mail.body }
  
  it "renders the headers" do
    mail.subject.should eq "Bestätigung der Anmeldung"
    mail.to.should eq(["top_leader@example.com"])
    mail.from.should eq(["jubla+noreply@puzzle.ch"])
  end 

  describe "event data" do
    it "renders set attributes only" do
      should =~ /Eventus/
      should =~ /Daten/
      should_not =~ /Kontaktperson:<br\/>Top Leader/
    end

    it "renders location if set" do
      event.location = "Eigerplatz 4\nPostfach 321\n3006 Bern"
      should =~ /Ort \/ Adresse:<br\/>Eigerplatz 4<br\/>Postfach 321<br\/>3006 Bern/
    end

    it "renders dates if set" do
      event.dates.clear
      event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
      should =~ /Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012/
    end

    it "renders multiple dates below each other" do
      event.dates.clear
      event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
      event.dates.build(label: 'Kurs', start_at: Date.parse('2012-10-21'))
      should =~ /Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012<br\/>Kurs: 21.10.2012/
    end
  end
  
  describe "#confirmation" do
    it { should =~ /Hallo Top/}
  end
  
  describe "#approval" do
    let(:approvers) do
      [Fabricate.build(:person, email: "approver0@example.com", first_name: 'firsty'),
       Fabricate.build(:person, email: "approver1@example.com", first_name: 'lasty')]
    end
    let(:mail) { Event::ParticipationMailer.approval(participation, approvers) }
    
    it "should send to approvers" do
      mail.to.should == ["approver0@example.com", "approver1@example.com"]
      mail.subject.should == 'Freigabe einer Kursanmeldung'
    end
    
    it { should =~ /Hallo firsty, lasty/}
    it { should =~ /Top Leader hat sich/}
  end
end
