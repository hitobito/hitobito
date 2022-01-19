# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  type                        :string
#  name                        :string           not null
#  number                      :string
#  motto                       :string
#  cost                        :string
#  maximum_participants        :integer
#  contact_id                  :integer
#  description                 :text
#  location                    :text
#  application_opening_at      :date
#  application_closing_at      :date
#  application_conditions      :text
#  kind_id                     :integer
#  state                       :string(60)
#  priorization                :boolean          default(FALSE), not null
#  requires_approval           :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  participant_count           :integer          default(0)
#  application_contact_id      :integer
#  external_applications       :boolean          default(FALSE)
#  applicant_count             :integer          default(0)
#  teamer_count                :integer          default(0)
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string
#  creator_id                  :integer
#  updater_id                  :integer
#

require 'spec_helper'

describe Event do

  let(:event) { events(:top_course) }

  context '#participations' do

    let(:event) { events(:top_event) }

    subject do
      Fabricate(Event::Role::Leader.name.to_sym,
                participation: Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: event))
      p = Fabricate(:event_participation, event: event)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p, label: 'Irgendwas')
      event.reload
    end
    its(:participant_count) { should == 2 }
  end

  context '#application_possible?' do

    context 'without opening and closing dates' do
      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        is_expected.to be_application_possible
      end
    end

    context 'with closing date in the future' do
      before { subject.application_closing_at = Time.zone.today + 1 }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

    end

    context 'with closing date today' do
      before { subject.application_closing_at = Time.zone.today }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with closing date in the past' do
      before { subject.application_closing_at = Time.zone.today - 1 }

      it 'is closed without maximum participant' do
        is_expected.not_to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end


    context 'with opening date in the past' do
      before { subject.application_opening_at = Time.zone.today - 1 }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening date today' do
      before { subject.application_opening_at = Time.zone.today }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening date in the future' do
      before { subject.application_opening_at = Time.zone.today + 1 }

      it 'is closed without maximum participant' do
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening and closing dates' do
      before do
        subject.application_opening_at = Time.zone.today - 2
        subject.application_closing_at = Time.zone.today + 2
      end

      it 'is open' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        is_expected.to be_application_possible
      end
    end

    context 'with opening and closing dates in the future' do
      before do
        subject.application_opening_at = Time.zone.today + 1
        subject.application_closing_at = Time.zone.today + 2
      end

      it 'is closed' do
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening and closing dates in the past' do
      before do
        subject.application_opening_at = Time.zone.today - 2
        subject.application_closing_at = Time.zone.today - 1
      end

      it 'is closed' do
        is_expected.not_to be_application_possible
      end
    end
  end

  context 'finders and scopes' do
    context '.in_year' do
      context 'one date' do
        before { set_start_finish(event, '2000-01-02') }

        it 'uses dates create_at to determine if event matches' do
          expect(Event.in_year(2000).size).to eq 1
          expect(Event.in_year(2001)).not_to be_present
          expect(Event.in_year(2000).first).to eq event
          expect(Event.in_year('2000').first).to eq event
        end

      end

      context 'starting at last day of year and another date in the following year' do
        before { set_start_finish(event, '2010-12-31 17:00') }
        before { set_start_finish(event, '2011-01-20') }

        it 'finds event in old year' do
          expect(Event.in_year(2010)).to eq([event])
        end

        it 'finds event in following year' do
          expect(Event.in_year(2011)).to eq([event])
        end

        it 'does not find event in past year' do
          expect(Event.in_year(2009)).to be_blank
        end
      end
    end

    context '.upcoming' do
      subject { Event.upcoming }
      it 'does not find past events' do
        set_start_finish(event, '2010-12-31 17:00')
        is_expected.not_to be_present
      end

      it 'does find upcoming event' do
        event.dates.create(start_at: 2.days.from_now, finish_at: 5.days.from_now)
        is_expected.to eq [event]
      end

      it 'does find running event' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now)
        is_expected.to eq [event]
      end

      it 'does find event ending at 5 to 12' do
        event.dates.create(start_at: 2.days.ago,
                           finish_at: Time.zone.now.midnight + 23.hours + 55.minutes)
        is_expected.to eq [event]
      end

      it 'does not find event ending at 5 past 12' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight - 5.minutes)
        is_expected.to be_blank
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: 1.day.from_now)
        is_expected.to eq [event]
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: Time.zone.now.midnight + 5.minutes)
        is_expected.to eq [event]
      end
    end

    context 'between' do
      it 'finds nothing if params nil' do
        event.dates.create(start_at: 1.year.ago, finish_at: 1.year.from_now)
        expect(Event.between(nil, nil)).to be_blank
        expect(Event.between(nil, Time.zone.now)).to be_blank
        expect(Event.between(Time.zone.now, nil)).to be_blank
      end

      context 'event with end and start date' do
        before do
          event.dates.create(start_at: 1.day.from_now, finish_at: 10.days.from_now)
        end

        it 'finds event with start_at overlay' do
          expect(Event.between(Time.zone.now, 2.days.from_now)).to eq [event]
        end

        it 'finds event with finish_at overlay' do
          expect(Event.between(9.days.from_now, 11.days.from_now)).to eq [event]
        end

        it 'finds event where start and finish_at is between dates' do
          expect(Event.between(Time.zone.now, 11.days.from_now)).to eq [event]
        end

        it 'finds event if the overlap is between start and finish_at' do
          expect(Event.between(2.days.from_now, 9.days.from_now)).to eq [event]
        end

        it 'does not find event if finish_at before start date' do
          expect(Event.between(11.days.from_now, 20.days.from_now)).to be_blank
        end

        it 'does not find event if start_at after end date' do
          expect(Event.between(1.day.ago, Time.zone.now)).to be_blank
        end
      end

      context 'event with only start date' do
        before do
          event.dates.create(start_at: 1.day.from_now)
        end

        it 'finds event with start_at overlay' do
          expect(Event.between(Time.zone.now, 2.days.from_now)).to eq [event]
        end

      end

    end

    context 'places_available' do
      let(:where_condition) do
        described_class.places_available.
          to_sql.sub(/.*(WHERE.*)$/, '\1')
      end

      it 'checks the maximum_participants' do
        expect(where_condition)
          .to match(/COALESCE\(maximum_participants, 0\) = 0/)
      end

      it 'compares the participant_count to the maximum_participants' do
        expect(where_condition)
          .to match('participant_count < maximum_participants')
      end
    end
  end

  context 'validations' do
    subject { event }

    it 'is not valid without event name' do
      e = Event.new(groups: [groups(:top_layer)],
                    dates: [Event::Date.new(start_at: Time.zone.now)])
      expect(e).to have(1).error_on(:name)
    end

    it 'is not valid without event_dates' do
      event.dates.clear
      expect(event.valid?).to be_falsey
      expect(event.errors[:dates]).to be_present
    end

    it 'is valid with application closing after opening' do
      subject.application_opening_at = Time.zone.today - 5
      subject.application_closing_at = Time.zone.today + 5
      subject.valid?

      is_expected.to be_valid
    end

    it 'is not valid with application closing before opening' do
      subject.application_opening_at = Time.zone.today - 5
      subject.application_closing_at = Time.zone.today - 6

      is_expected.not_to be_valid
    end

    it 'is valid with application closing and without opening' do
      subject.application_closing_at = Time.zone.today - 6

      is_expected.to be_valid
    end

    it 'is valid with application opening and without closing' do
      subject.application_opening_at = Time.zone.today - 6

      is_expected.to be_valid
    end

    it 'requires groups' do
      subject.group_ids = []

      is_expected.to have(1).error_on(:group_ids)
    end
  end

  context '#init_questions' do
    it 'adds 3 default questions for courses' do
      e = Event::Course.new
      e.init_questions
      expect(e.application_questions.size).to eq(3)
    end

    it 'does nothing for regular events' do
      e = Event.new
      e.init_questions
      expect(e.application_questions).to be_blank
    end
  end

  context 'event_dates' do
    let(:e) { event }

    it "should update event_date's start_at time" do
      d = Time.zone.local(2012, 12, 12).to_date
      e.dates.create(label: 'foo', start_at: d, finish_at: d)
      ed = e.dates.first
      e.update(
        dates_attributes: {
          '0' => { start_at_date: d, start_at_hour: 18, start_at_min: 10, id: ed.id }
        }
      )
      expect(e.dates.first.start_at).to eq(Time.zone.local(2012, 12, 12, 18, 10))
    end

    it "should update event_date's finish_at date" do
      d1 = Time.zone.local(2012, 12, 12).to_date
      d2 = Time.zone.local(2012, 12, 13).to_date
      e.dates.create(label: 'foo', start_at: d1, finish_at: d1)
      ed = e.dates.first
      e.update(dates_attributes: { '0' => { finish_at_date: d2, id: ed.id } })
      expect(e.dates.first.finish_at).to eq(Time.zone.local(2012, 12, 13, 0, 0))
    end

  end

  context 'participation role labels' do

    let(:event) { events(:top_event) }
    let(:participation) { Fabricate(:event_participation, event: event) }

    it 'should have 2 different labels' do
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: participation, label: 'Just label')
      event.reload

      expect(event.participation_role_labels.count).to eq 2
    end

    it 'should have no labels' do
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
      event.reload

      expect(event.participation_role_labels.count).to eq 0
    end

  end

  context 'participant and application counts' do
    def create_participation(prio, attrs = { active: true })
      participation_attrs = prio == :prio1 ? { event: event } : { event: another_event }
      application_attrs = prio == :prio1 ? { priority_1: event } : { priority_1: another_event, priority_2: event } # rubocop:disable Metrics/LineLength

      participation = Fabricate(:event_participation, participation_attrs.merge(attrs))
      participation.create_application!(application_attrs)
      Fabricate(event.participant_types.first.name.to_sym, participation: participation)
      participation.save!

      Event::ParticipantAssigner.new(event, participation).add_participant if attrs[:active]
      participation
    end

    def assert_counts(attrs)
      event.reload
      expect(event.participant_count).to eq attrs[:participant]
      expect(event.applicant_count).to eq attrs[:applicant]
    end

    context 'for basic event' do
      let(:event) { events(:top_event) }

      it 'should be zero if no participations/applications available' do
        expect(event.participations.count).to eq 0
        expect(
          Event::Application.where('priority_2_id = ? OR priority_3_id = ?', event.id, event.id)
        ).to be_empty

        assert_counts(participant: 0, applicant: 0)
      end

      it 'should not count leaders' do
        leader = Fabricate(:event_participation, event: event, active: true)
        Fabricate(Event::Role::Leader.name.to_sym, participation: leader, label: 'Foolabel')

        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count participations with multiple roles in regular event correctly' do
        p = Fabricate(:event_participation, event: event, active: true)

        Fabricate(Event::Role::Cook.name.to_sym, participation: p)
        assert_counts(participant: 0, applicant: 0)

        r = Fabricate(Event::Role::Participant.name.to_sym, participation: p)
        assert_counts(participant: 1, applicant: 1)

        r.destroy
        assert_counts(participant: 0, applicant: 0)
      end
    end

    context 'for course' do
      let(:event) { events(:top_course) }
      let(:another_event) do
        Event::Course.create!(
          name: 'Another',
          group_ids: event.group_ids,
          dates: event.dates,
          kind: event_kinds(:slk)
        )
      end

      it 'should count participations with multiple roles in course correctly' do
        p = Fabricate(:event_participation,
                      event: event,
                      active: true,
                      application: Fabricate(:event_application, priority_1: event))

        Fabricate(Event::Role::Cook.name.to_sym, participation: p)
        assert_counts(participant: 0, applicant: 0)

        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
        assert_counts(participant: 1, applicant: 1)

        # in courses, participant roles are removed like that
        Event::ParticipantAssigner.new(event, p).remove_participant
        assert_counts(participant: 0, applicant: 1)

        p.destroy!
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count active prio 1 participations correctly' do
        p = create_participation(:prio1)
        assert_counts(participant: 1, applicant: 1)

        p.destroy!
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count active prio 2 participations correctly' do
        create_participation(:prio2)
        assert_counts(participant: 1, applicant: 1)
      end

      it 'should count pending prio 1 participations correctly' do
        create_participation(:prio1, active: false)
        assert_counts(participant: 0, applicant: 1)
      end

      it 'should count pending prio 2 participations correctly' do
        create_participation(:prio2, active: false)
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should sum participations/applications correctly' do
        leader = Fabricate(:event_participation, event: event, active: true)
        Fabricate(Event::Role::Leader.name.to_sym, participation: leader, label: 'Foolabel')

        create_participation(:prio1)
        create_participation(:prio2)
        create_participation(:prio1, active: false)
        create_participation(:prio2, active: false)

        assert_counts(participant: 2, applicant: 3)
      end

    end
  end

  context 'destroyed associations' do
    let(:event) { events(:top_course) }

    it 'destroys everything with event' do
      expect do
        expect do
          expect do
            expect do
              expect { event.destroy }.to change { Event.count }.by(-1)
            end.to change { Event::Participation.count }.by(-1)
          end.to change { Event::Role.count }.by(-1)
        end.to change { Event::Date.count }.by(-1)
      end.to change { Event::Question.count }.by(-3)
    end

    it 'nullifies contact on person destroy' do
      event.update(contact: people(:top_leader))
      event.contact.destroy

      expect(event.reload.contact_id).to be_nil
    end

    it 'keeps destroyed kind' do
      event.kind.destroy
      event.reload

      expect(event.kind).to be_present
    end

    context 'groups' do
      let(:group_one) { groups(:bottom_group_one_one) }
      let(:group_two) { groups(:bottom_group_one_two) }
      let(:event) { Fabricate(:event, groups: [group_one, group_two]) }

      it 'keeps destroyed groups' do
        expect(event.groups.size).to eq(2)

        group_two.destroy
        expect(group_two).to be_deleted
        event.reload

        expect(event.groups.size).to eq(2)
      end
    end

  end

  context 'contact attributes' do

    let(:event) { events(:top_course) }

    it 'does not accept invalid person attributes' do
      event.update({ required_contact_attrs: ['foobla'],
                     hidden_contact_attrs: ['foofofofo'] })

      expect(event.errors.full_messages.first)
        .to match(/'foobla' ist kein gültiges Personen-Attribut/)
      expect(event.errors.full_messages.second)
        .to match(/'foofofofo' ist kein gültiges Personen-Attribut/)
    end

    it 'is not possible to set same attr as hidden and required' do
      event.update({ required_contact_attrs: ['nickname'],
                     hidden_contact_attrs: ['nickname'] })

      expect(event.errors.full_messages.first)
        .to match(/'nickname' kann nicht als obligatorisch und 'nicht anzeigen' gesetzt werden/)
    end

    it 'is not possible to set mandatory attr as hidden' do
      event.update({ hidden_contact_attrs: ['email'] })

      expect(event.errors.full_messages.first)
        .to match(/'email' ist ein Pflichtfeld und kann nicht als optional oder 'nicht anzeigen' gesetzt werden/) # rubocop:disable Metrics/LineLength
    end

    it 'is not possible to set contact association as required' do
      event.update({ required_contact_attrs: ['additional_emails'] })

      expect(event.errors.full_messages.first)
        .to match(/'additional_emails' ist kein gültiges Personen-Attribut/)
    end

    it 'is possible to hide contact association' do
      event.update({ hidden_contact_attrs: ['additional_emails'] })

      expect(event.reload.hidden_contact_attrs).to include('additional_emails')
    end

  end

  context '#duplicate' do

    let(:event) { events(:top_event) }

    it 'resets participant counts' do
      Fabricate(Event::Role::Leader.name,
                participation: Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name,
                participation: Fabricate(:event_participation, event: event))

      expect(event.participant_count).not_to eq(0)
      expect(event.teamer_count).not_to eq(0)

      d = event.duplicate
      expect(d.participant_count).to eq(0)
      expect(d.teamer_count).to eq(0)
      expect(d.applicant_count).to eq(0)
    end

    it 'keeps empty questions' do
      d = event.duplicate
      expect(d.application_questions.size).to eq(0)
    end

    it 'copies existing questions' do
      event.questions << Fabricate(:event_question)
      event.questions << Fabricate(:event_question, admin: true)
      d = event.duplicate

      expect do
        d.dates << Fabricate.build(:event_date, event: d)
        d.save!
      end.to change { Event::Question.count }.by(2)
    end

    it 'copies all groups' do
      event.groups << Fabricate(Group::TopGroup.name.to_sym,
                                name: 'CCC', parent: groups(:top_layer))

      d = event.duplicate
      expect(d.group_ids.size).to eq(2)
    end

  end

  context 'group timestamps' do
    let(:group) { groups(:top_layer) }

    it 'does not modify the group timestamps when creating an event' do
      expect do
        Event.new(name: 'dummy',
                  groups: [group],
                  dates: [Event::Date.new(start_at: Time.zone.now)])
             .save!
      end.not_to(change { group.updated_at })
    end

    it 'does not modify the updater id when creating an event' do
      expect do
        Event.new(name: 'dummy',
                  groups: [group],
                  dates: [Event::Date.new(start_at: Time.zone.now)])
             .save!
      end.not_to(change { group.updater_id })
    end

  end

  context 'globally visible' do
    subject do
      described_class.new(
        type: nil,
        groups: [groups(:bottom_layer_one)]
      ).tap do |event|
        event.dates.build(start_at: Time.zone.parse('2012-3-01'))
      end
    end

    it 'is a flag on the event' do
      is_expected.to respond_to :globally_visible
      is_expected.to respond_to :globally_visible?
    end

    it 'is a used attribute' do
      is_expected.to be_attr_used(:globally_visible)
    end


    context 'has a default set by settings, which' do
      it 'can be off by default' do
        expect(subject.read_attribute(:globally_visible)).to be_nil
        allow(Settings.event).to receive(:globally_visible_by_default).and_return(false)

        expect(subject.globally_visible).to be false
        is_expected.to_not be_globally_visible
      end

      it 'can be on by default' do
        expect(subject.read_attribute(:globally_visible)).to be_nil
        allow(Settings.event).to receive(:globally_visible_by_default).and_return(true)

        expect(subject.globally_visible).to be true
        is_expected.to be_globally_visible
      end

      it 'does not affect explicit true setting' do
        subject.globally_visible = true
        expect(subject.read_attribute(:globally_visible)).to be true
        allow(Settings.event).to receive(:globally_visible_by_default).and_return(false)

        expect(subject.globally_visible).to be true
        is_expected.to be_globally_visible
      end

      it 'does not affect explicit false setting' do
        subject.globally_visible = false
        expect(subject.read_attribute(:globally_visible)).to be false
        allow(Settings.event).to receive(:globally_visible_by_default).and_return(true)

        expect(subject.globally_visible).to be false
        is_expected.to_not be_globally_visible
      end
    end
  end

  context 'shared_access_token' do
    let(:token) { 'p3UEhxgz4Qj1d3Q3qVfy' } # Devise.friendly_token

    it 'is an attribute' do
      is_expected.to respond_to(:shared_access_token)
      is_expected.to respond_to(:shared_access_token)
    end

    it 'can be checked' do
      subject.shared_access_token = token

      is_expected.to be_token_accessible(token)
    end

    it 'is not token accessible if unset' do
      subject.shared_access_token = nil

      is_expected.to_not be_token_accessible(token)
    end

    it 'is not token accessible if no token provided' do
      subject.shared_access_token = token

      is_expected.to_not be_token_accessible(nil)
    end

    it 'is not token accessible if both values are nil' do
      subject.shared_access_token = nil

      is_expected.to_not be_token_accessible(nil)
    end

    it 'is not token accessible if wrong token provided' do
      subject.shared_access_token = token.downcase

      is_expected.to_not be_token_accessible(token.succ.upcase)
    end

    it 'is set upon validation if empty' do
      subject.shared_access_token = nil

      expect { subject.valid? }.to change(subject, :shared_access_token).from(nil)
    end

    it 'is not overwritten if set' do
      subject.shared_access_token = token

      expect { subject.valid? }.to_not change(subject, :shared_access_token)
    end
  end

  context 'role types' do
    around(:example) do |example|
      types = Event.role_types
      example.run
      Event.role_types = types
    end

    it '.register_role_type' do
      role_type = Class.new(Event::Role)
      expect { Event.register_role_type(role_type) }.to change {
        Event.role_types.length
      }.by(1)
      expect(Event.role_types).to include(role_type)

      # should not raise, two wagons might register the same role
      Event.register_role_type(role_type)

      other = Class.new
      expect { Event.register_role_type(other) }.to raise_error(ArgumentError)
    end

    it '.disable_role_type' do
      role_type = Event.role_types.first
      expect { Event.disable_role_type(role_type) }.to change {
        Event.role_types.length
      }.by(-1)
      expect(Event.role_types).not_to include(role_type)

      # should not raise, two wagons might disable the same role
      Event.disable_role_type(role_type)

      other = Class.new
      expect { Event.register_role_type(other) }.to raise_error(ArgumentError)
    end
  end

  def set_start_finish(event, start_at)
    start_at = Time.zone.parse(start_at)
    event.dates.create!(start_at: start_at, finish_at: start_at + 5.days)
  end

end
