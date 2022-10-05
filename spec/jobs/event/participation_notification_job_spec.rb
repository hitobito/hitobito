# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationNotificationJob do

  let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

  let(:participant) { people(:top_leader) }
  let(:receiver) { people(:bottom_member) }

  let(:participation) do
    Fabricate(:event_participation,
              event: course,
              person: participant,
              application: Fabricate(:event_application,
                                     priority_2: Fabricate(:course, kind: course.kind)))
  end

  let(:person)  { Fabricate(:person, email: 'anybody@example.com') }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  subject { described_class.new(participation) }

  context 'with event contact' do
    before do
      course.update(
        contact: receiver,
        notify_contact_on_participations: notify
      )
    end

    context 'when notifying' do
      let(:notify) { true }

      it 'sends notification email' do
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        expect(ActionMailer::Base.deliveries.first.subject).to eq('Anlass: Teilnehmer-/in hat sich angemeldet')
      end
    end

    context 'when not notifying' do
      let(:notify) { false }

      it 'sends nothing' do
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end

  context 'without event contact' do
    context 'when notifying' do
      let(:notify) { true }

      it 'does not send notification email' do
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end

    context 'when not notifying' do
      let(:notify) { false }

      it 'sends nothing' do
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end
end
