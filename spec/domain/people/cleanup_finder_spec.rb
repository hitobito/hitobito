# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::CleanupFinder do

  let(:people_without_roles) { 3.times.map { Fabricate(:person) } }
  let(:people_with_expired_roles) { 3.times.map { Fabricate(Group::BottomGroup::Member.name.to_sym,
                                                            group: groups(:bottom_group_one_one),
                                                            created_at: 11.months.ago,
                                                            deleted_at: 10.months.ago).person } }
  let(:people_with_roles) { 3.times.map { Fabricate(Group::BottomGroup::Member.name.to_sym,
                                                    group: groups(:bottom_group_one_one)).person } }

  subject { People::CleanupFinder.new.run }
  context '#run' do
    context 'people with expired roles outside cutoff duration' do
      let!(:people) { people_with_expired_roles }

      before do
        expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_roles).and_return(9)
      end

      context 'with current_sign_in_at outside cutoff duration' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
          people.each { |p| p.update!(current_sign_in_at: 13.months.ago) }
        end

        it 'finds them' do
          expect(subject).to match_array(people)
        end

        it 'does not find them with event participation in the future' do
          event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
          people.each do |p|
            Event::Participation.create!(event: event, person: p)
          end

          expect(subject).to_not match_array(people)
        end

        it 'finds them with event participation in the past' do
          event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago)])
          people.each do |p|
            Event::Participation.create!(event: event, person: p)
          end

          expect(subject).to match_array(people)
        end
      end

      context 'with current_sign_in_at nil' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

          people.each { |p| p.update!(current_sign_in_at: nil) }
        end

        it 'finds them' do
          expect(subject).to match_array(people)
        end
      end

      context 'with current_sign_in_at inside cutoff duration' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
          people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
        end

        it 'does not find them' do
          expect(subject).to_not match_array(people)
        end
      end
    end

    context 'people with expired roles inside cutoff duration' do
      let!(:people) { people_with_expired_roles }

      before do
        expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_roles).and_return(12)
      end

      context 'with current_sign_in_at outside cutoff duration' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
          people.each { |p| p.update!(current_sign_in_at: 13.months.ago) }
        end

        it 'does not find them' do
          expect(subject).to_not match_array(people)
        end

        it 'does not find them' do
          expect(subject).to_not match_array(people)
        end

        it 'does not find them with event participation in the future' do
          event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
          people.each do |p|
            Event::Participation.create!(event: event, person: p)
          end

          expect(subject).to_not match_array(people)
        end

        it 'does not find them with event participation in the past' do
          event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
          people.each do |p|
            Event::Participation.create!(event: event, person: p)
          end

          expect(subject).to_not match_array(people)
        end
      end

      context 'with current_sign_in_at nil' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

          people.each { |p| p.update!(current_sign_in_at: nil) }
        end

        it 'does not find them' do
          expect(subject).to_not match_array(people)
        end
      end

      context 'with current_sign_in_at inside cutoff duration' do
        before do
          expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
          people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
        end

        it 'does not find them' do
          expect(subject).to_not match_array(people)
        end
      end
    end

    it 'finds people without any roles' do
      people_without_roles
      expect(subject).to match_array(people_without_roles)
    end

    it 'does not find people with active roles' do
      people_with_roles
      expect(subject).to_not match_array(people_with_roles)
    end
  end

end
