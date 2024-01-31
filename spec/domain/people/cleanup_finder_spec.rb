# frozen_string_literal: true

#  Copyright (c) 2023-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::CleanupFinder do

  let!(:entries) { Fabricate.times(3, :person) }

  let(:cutoff_durations) { Settings.people.cleanup_cutoff_duration }

  let(:sign_in_cutoff_time) { cutoff_durations.regarding_current_sign_in_at.months.ago }
  let(:role_cutoff_time) { cutoff_durations.regarding_roles.months.ago }
  let(:participation_cutoff_time) { cutoff_durations.regarding_participations.months.ago }

  let(:future_event) do
    Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
  end
  let(:past_event) do
    Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
  end

  def create_role(person, deleted_at:, created_at: 101.years.ago)
    Fabricate(
      Group::BottomGroup::Member.name.to_sym,
      person: person,
      group: groups(:bottom_group_one_one),
      created_at: created_at,
      deleted_at: deleted_at
    )
  end

  context '#run' do
    it 'finds matching people' do
      expect(subject.run).to include(*entries)
    end

    it 'finds people without roles' do
      expect(entries.first.roles.with_deleted).to be_empty
      expect(subject.run).to include(entries.first)
    end

    it 'finds people with deleted roles older or equal than the cutoff time' do
      create_role(entries.first, deleted_at: role_cutoff_time - 100)
      create_role(entries.second, deleted_at: role_cutoff_time)
      expect(subject.run).to include(entries.first, entries.second)
    end

    it 'does not find people with deleted roles younger than the cutoff time' do
      create_role(entries.first, deleted_at: role_cutoff_time + 100)
      expect(subject.run).not_to include(entries.first)
    end

    it 'does not find people with deleted roles older and younger than the cutoff time' do
      create_role(entries.first, deleted_at: role_cutoff_time - 100)
      create_role(entries.first, deleted_at: role_cutoff_time + 100)
      expect(subject.run).not_to include(entries.first)
    end

    it 'does not find people with active roles' do
      create_role(entries.first, deleted_at: nil)
      expect(subject.run).not_to include(entries.first)
    end

    it 'finds people with participations at past events' do
      Event::Participation.create!(event: past_event, person: entries.first)
      expect(subject.run).to include(entries.first)
    end

    it 'does not find people with participations at future events' do
      Event::Participation.create!(event: future_event, person: entries.first)
      expect(subject.run).not_to include(entries.first)
    end

    it 'does not find people with participations at past and future events' do
      Event::Participation.create!(event: past_event, person: entries.first)
      Event::Participation.create!(event: future_event, person: entries.first)
      expect(subject.run).not_to include(entries.first)
    end

    it 'finds people with current_sign_in_at older than the cutoff time' do
      entries.first.update!(current_sign_in_at: sign_in_cutoff_time - 100)
      expect(subject.run).to include(entries.first)
    end

    it 'does not find people with current_sign_in_at younger than the cutoff time' do
      entries.first.update!(current_sign_in_at: sign_in_cutoff_time + 100)
      expect(subject.run).not_to include(entries.first)
    end
  end

end
