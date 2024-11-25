# frozen_string_literal: true

#  Copyright (c) 2023-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::CleanupFinder do
  let!(:entries) { Fabricate.times(3, :person) }

  let(:cutoff_durations) { Settings.people.cleanup_cutoff_duration }

  let(:sign_in_cutoff_time) { cutoff_durations.regarding_current_sign_in_at.months.ago }
  let(:role_cutoff_date) { cutoff_durations.regarding_roles.months.ago.to_date }
  let(:participation_cutoff_time) { cutoff_durations.regarding_participations.months.ago }

  let(:future_event) do
    Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
  end
  let(:past_event) do
    Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
  end

  def create_role(person, end_on:, start_on: 101.years.ago)
    Fabricate(
      Group::BottomGroup::Member.name.to_sym,
      person: person,
      group: groups(:bottom_group_one_one),
      start_on: start_on,
      end_on: end_on
    )
  end

  context "#run" do
    it "finds matching people" do
      expect(subject.run).to include(*entries)
    end

    it "finds people without roles" do
      expect(entries.first.roles.with_inactive).to be_empty
      expect(subject.run).to include(entries.first)
    end

    it "finds people with ended roles older or equal than the cutoff time" do
      create_role(entries.first, end_on: role_cutoff_date - 1)
      create_role(entries.second, end_on: role_cutoff_date)
      expect(subject.run).to include(entries.first, entries.second)
    end

    it "does not find people with ended roles younger than the cutoff time" do
      create_role(entries.first, end_on: role_cutoff_date + 1)
      expect(subject.run).not_to include(entries.first)
    end

    it "does not find people with deleted roles older and younger than the cutoff time" do
      create_role(entries.first, end_on: role_cutoff_date - 1)
      create_role(entries.first, end_on: role_cutoff_date + 1)
      expect(subject.run).not_to include(entries.first)
    end

    it "does not find people with active roles" do
      create_role(entries.first, end_on: nil)
      expect(subject.run).not_to include(entries.first)
    end

    it "finds people with participations at past events" do
      Event::Participation.create!(event: past_event, person: entries.first)
      expect(subject.run).to include(entries.first)
    end

    it "does not find people with participations at future events" do
      Event::Participation.create!(event: future_event, person: entries.first)
      expect(subject.run).not_to include(entries.first)
    end

    it "does not find people with participations at past and future events" do
      Event::Participation.create!(event: past_event, person: entries.first)
      Event::Participation.create!(event: future_event, person: entries.first)
      expect(subject.run).not_to include(entries.first)
    end

    it "finds people with current_sign_in_at older than the cutoff time" do
      entries.first.update!(current_sign_in_at: sign_in_cutoff_time - 1)
      expect(subject.run).to include(entries.first)
    end

    it "does not find people with current_sign_in_at younger than the cutoff time" do
      entries.first.update!(current_sign_in_at: sign_in_cutoff_time + 1)
      expect(subject.run).not_to include(entries.first)
    end
  end
end
