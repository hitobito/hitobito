# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationCleanupJob do
  let(:participations_with_additional_information) { 3.times.map { Fabricate(:event_participation, additional_information: Faker::Food.allergen) } }
  let(:participations_without_additional_information) { 3.times.map { Fabricate(:event_participation) } }
  let(:participations) { participations_with_additional_information + participations_without_additional_information }

  subject { described_class.new.perform_internal }

  context 'with last event date inside cutoff duration' do
    before do
      expect(Settings.event.participations).to receive(:delete_additional_information_after_months).and_return(3)
      Event::Date.where(event_id: participations.map(&:event_id)).update_all(finish_at: 2.months.ago)
    end

    it 'does not clean participations additional_information' do
      subject

      participations_with_additional_information.each do |p|
        expect(p.additional_information).to_not be_nil
      end

      participations_without_additional_information.each do |p|
        expect(p.additional_information).to be_nil
      end
    end
  end

  context 'with last event date outside cutoff duration' do
    before do
      expect(Settings.event.participations).to receive(:delete_additional_information_after_months).and_return(3)
      Event::Date.where(event_id: participations.map(&:event_id)).update_all(finish_at: 4.months.ago)
    end

    it 'cleans participations additional_information' do
      subject

      participations_with_additional_information.each do |p|
        p.reload
        expect(p.additional_information).to be_nil
      end

      participations_without_additional_information.each do |p|
        expect(p.additional_information).to be_nil
      end
    end
  end
end
