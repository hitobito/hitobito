# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationMailer do

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event) }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }

  before do
    Fabricate(:phone_number, contactable: person, public: true)
  end

  subject { mail.parts.first.body }

  it 'includes an html and a pdf part' do
    mail.parts.first.content_type.should eq "text/html; charset=UTF-8"
    mail.parts.second.content_type.should eq "application/pdf; filename=\"Eventus_Top Leader.pdf\""
  end

  describe 'event data' do
    it 'renders set attributes only' do
      should =~ /Eventus/
      should =~ /Daten/
      should_not =~ /Kontaktperson:<br\/>Top Leader/
    end

    it 'renders location if set' do
      event.location = "Eigerplatz 4\nPostfach 321\n3006 Bern"
      should =~ /Ort \/ Adresse:<br\/>Eigerplatz 4<br\/>Postfach 321<br\/>3006 Bern/
    end

    it 'renders dates if set' do
      event.dates.clear
      event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
      should =~ /Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012/
    end

    it 'renders multiple dates below each other' do
      event.dates.clear
      event.dates.build(label: 'Vorweekend', start_at: Date.parse('2012-10-18'), finish_at: Date.parse('2012-10-21'))
      event.dates.build(label: 'Kurs', start_at: Date.parse('2012-10-21'))
      should =~ /Daten:<br\/>Vorweekend: 18.10.2012 - 21.10.2012<br\/>Kurs: 21.10.2012/
    end

    it 'renders participant info' do
      should =~ %r{Teilnehmer/-in:<br/>}
      should =~ %r{<strong>Top Leader</strong><p> Supertown</p><p><a href="mailto:top_leader@example.com">top_leader@example.com</a>}
    end

    it 'renders questions if present' do
      question = event_questions(:top_ov)
      event.questions << event_questions(:top_ov)
      participation.answers.create!(question_id: question.id, answer: 'GA')

      should =~ %r{Fragen:.*GA}
    end
  end

  describe '#confirmation' do

    it 'renders the headers' do
      mail.subject.should eq 'Bestätigung der Anmeldung'
      mail.to.should eq(['top_leader@example.com'])
      mail.from.should eq(['noreply@localhost'])
    end

    it { should =~ /Hallo Top/ }

    it 'contains participation url' do
      should =~ %r{test.host/groups/#{event.groups.first.id}/events/#{event.id}/participations/#{participation.id}}
    end

    it 'sends to all email addresses of participant' do
      person.update_attributes!(email: nil)
      e1 = Fabricate(:additional_email, contactable: person, mailings: true, public: true)
      participation.person.reload
      mail.to.should eq [e1.email]
      should =~ /a href="mailto:#{e1.email}"/
    end

  end

  describe '#approval' do
    subject { mail.body }

    let(:approvers) do
      [Fabricate(:person, email: 'approver0@example.com', first_name: 'firsty'),
       Fabricate(:person, email: 'approver1@example.com', first_name: 'lasty')]
    end
    let(:mail) { Event::ParticipationMailer.approval(participation, approvers) }

    it 'sends to all email addresses of approvers' do
      e1 = Fabricate(:additional_email, contactable: approvers[0], mailings: true)
      e2 = Fabricate(:additional_email, contactable: approvers[0], mailings: true)
      Fabricate(:additional_email, contactable: approvers[1], mailings: false)

      mail.to.should eq ['approver0@example.com', 'approver1@example.com', e1.email, e2.email]
      mail.subject.should eq 'Freigabe einer Kursanmeldung'
    end

    it { should =~ /Hallo firsty, lasty/ }
    it { should =~ /Top Leader hat sich/ }
  end
end
