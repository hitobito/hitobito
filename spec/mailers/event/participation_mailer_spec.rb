# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationMailer do
  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event) }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }

  before do
    Fabricate(:phone_number, contactable: person, public: true)
  end

  subject { mail.parts.first.body }

  it "includes an html and a pdf part" do
    expect(mail.parts.first.content_type).to eq "text/html; charset=UTF-8"
    expect(mail.parts.second.content_type).to eq "application/pdf; filename=eventus-top_leader.pdf"
  end

  it "deals with quotes in event name" do
    event.update(name: %(Now "with" quotes))
    expect(mail.parts.first.content_type).to eq "text/html; charset=UTF-8"
    expect(mail.parts.second.content_type).to eq "application/pdf; filename=now_with_quotes-top_leader.pdf"
  end

  describe "event data" do
    it "renders set attributes only" do
      is_expected.to match(/Eventus/)
      is_expected.to match(/Daten/)
      is_expected.not_to match(/Kontaktperson:<br\/>Top Leader/)
    end

    it "renders location if set" do
      event.location = "Eigerplatz 4\nPostfach 321\n3006 Bern"
      is_expected.to match(/Ort \/ Adresse:<br\/>Eigerplatz 4<br\/>Postfach 321<br\/>3006 Bern/)
    end

    it "renders dates if set" do
      event.dates.clear
      event.dates.build(label: "Vorweekend", start_at: Date.parse("2012-10-18"), finish_at: Date.parse("2012-10-21"))
      is_expected.to match(/Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012/)
    end

    it "renders multiple dates below each other" do
      event.dates.clear
      event.dates.build(label: "Vorweekend", start_at: Date.parse("2012-10-18"), finish_at: Date.parse("2012-10-21"))
      event.dates.build(label: "Kurs", start_at: Date.parse("2012-10-21"))
      is_expected.to match(/Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012<br\/>Kurs: 21.10.2012/)
    end

    it "renders participant info" do
      is_expected.to match(%r{Teilnehmer/-in:<br/>})
      is_expected.to match(%r{<strong>Top Leader</strong><p> Supertown</p><p><a href="mailto:top_leader@example.com">top_leader@example.com</a>})
    end

    it "renders application questions if present" do
      question = event_questions(:top_ov)
      event.questions << event_questions(:top_ov)
      question2 = event.questions.create!(question: "foo", admin: true)
      participation.answers.detect { |a| a.question_id == question.id }.update!(answer: "GA")
      participation.answers.detect { |a| a.question_id == question2.id }.update!(answer: "Bar")

      is_expected.to match(%r{Fragen:.*GA})
      is_expected.not_to match(%r{Fragen:.*Bar})
    end
  end

  describe "#confirmation" do
    it "renders the headers" do
      expect(mail.subject).to eq "Bestätigung der Anmeldung"
      expect(mail.to).to eq(["top_leader@example.com"])
      expect(mail.from).to eq(["noreply@localhost"])
    end

    it { is_expected.to match(/Hallo Top/) }

    it "contains participation url" do
      is_expected.to match(%r{test.host/groups/#{event.groups.first.id}/events/#{event.id}/participations/#{participation.id}})
    end

    it "sends to all email addresses of participant" do
      person.update!(email: nil)
      e1 = Fabricate(:additional_email, contactable: person, mailings: true, public: true)
      participation.person.reload
      expect(mail.to).to eq [e1.email]
      is_expected.to match(/a href="mailto:#{e1.email}"/)
    end
  end

  describe "#approval" do
    subject { mail.body }

    let(:approvers) do
      [Fabricate(:person, email: "approver0@example.com", first_name: "firsty"),
       Fabricate(:person, email: "approver1@example.com", first_name: "lasty")]
    end
    let(:mail) { Event::ParticipationMailer.approval(participation, approvers) }

    it "sends to all email addresses of approvers" do
      e1 = Fabricate(:additional_email, contactable: approvers[0], mailings: true)
      e2 = Fabricate(:additional_email, contactable: approvers[0], mailings: true)
      Fabricate(:additional_email, contactable: approvers[1], mailings: false)

      expect(mail.to).to match_array(["approver0@example.com", "approver1@example.com", e1.email, e2.email])
      expect(mail.subject).to eq "Freigabe einer Kursanmeldung"
    end

    it { is_expected.to match(/Hallo firsty, lasty/) }
    it { is_expected.to match(/Top Leader hat sich/) }
  end

  describe "#cancel" do
    let(:mail) { Event::ParticipationMailer.cancel(event, person) }

    subject { mail.body }

    it "renders dates if set" do
      event.dates.clear
      event.dates.build(label: "Vorweekend", start_at: Date.parse("2012-10-18"), finish_at: Date.parse("2012-10-21"))
      is_expected.to match(/Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012/)
    end

    it "renders multiple dates below each other" do
      event.dates.clear
      event.dates.build(label: "Vorweekend", start_at: Date.parse("2012-10-18"), finish_at: Date.parse("2012-10-21"))
      event.dates.build(label: "Anlass", start_at: Date.parse("2012-10-21"))
      is_expected.to match(/Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012<br\/>Anlass: 21.10.2012/)
    end

    it "renders the headers" do
      expect(mail.subject).to eq "Bestätigung der Abmeldung"
      expect(mail.to).to eq(["top_leader@example.com"])
      expect(mail.from).to eq(["noreply@localhost"])
    end

    it { is_expected.to match(/Hallo Top/) }
  end
end
