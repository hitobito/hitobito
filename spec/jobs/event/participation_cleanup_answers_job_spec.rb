# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationCleanupAnswersJob do
  let(:event) { events(:top_course) }
  let!(:question) { Fabricate(:event_question, event: event) }

  subject(:job) { described_class.new }

  it 'reschedules job' do
    expect { subject.perform }.to change { Delayed::Job.count }.by(1)
  end

  context 'without cutoff' do
    it 'noops' do
      expect { subject.perform }.not_to change { Event::Answer.count }
    end
  end

  context 'with cutoff' do
    let(:cutoff) { 3 }
    let(:start_at) { event.dates.first.start_at }
    let(:cutoff_date) { start_at + cutoff.months }

    before do
      allow(Settings.event.participations)
        .to receive(:delete_answers_after_months).and_return(cutoff)
    end

    it 'keeps answer when running before cutoff date' do
      travel_to(cutoff_date - 1.day) do
        expect { subject.perform }.not_to change { Event::Answer.count }
      end
    end

    it 'removes answer when running on cutoff date' do
      travel_to(cutoff_date) do
        expect { subject.perform }.to change { Event::Answer.count }.by(-1)
      end
    end

    it 'removes answer when running after cutoff date' do
      travel_to(cutoff_date + 1.day) do
        expect { subject.perform }.to change { Event::Answer.count }.by(-1)
      end
    end

    it 'keeps answer when start_at would apply but finish_at at does not' do
      event.dates.first.update!(finish_at: start_at + 1.day)
      travel_to(cutoff_date) do
        expect { subject.perform }.not_to change { Event::Answer.count }
      end
    end

    it 'removes answer when start_at and finish_at apply' do
      event.dates.first.update!(finish_at: start_at)
      travel_to(cutoff_date) do
        expect { subject.perform }.to change { Event::Answer.count }.by(-1)
      end
    end

    it 'keeps answer when later date does not apply' do
      event.dates.create!(start_at: start_at + 1.day)
      travel_to(cutoff_date) do
        expect { subject.perform }.not_to change { Event::Answer.count }
      end
    end

    it 'removes answer when later date does apply' do
      event.dates.create!(start_at: start_at - 1.day)
      travel_to(cutoff_date) do
        expect { subject.perform }.to change { Event::Answer.count }.by(-1)
      end
    end
  end
end
