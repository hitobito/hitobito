# frozen_string_literal: true

#  Copyright (c) 2023-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::CleanupFinder do
  let!(:people) { Fabricate.times(3, :person) }

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
    subject { People::CleanupFinder.new.run }

    it "finds matching people" do
      expect(subject).to include(*people)
    end

    it "finds people without roles" do
      expect(people.first.roles.with_inactive).to be_empty
      expect(subject).to include(people.first)
    end

    it "finds people with ended roles older or equal than the cutoff time" do
      create_role(people.first, end_on: role_cutoff_date - 1)
      create_role(people.second, end_on: role_cutoff_date)
      expect(subject).to include(people.first, people.second)
    end

    it "does not find people with ended roles younger than the cutoff time" do
      create_role(people.first, end_on: role_cutoff_date + 1)
      expect(subject).not_to include(people.first)
    end

    it "does not find people with deleted roles older and younger than the cutoff time" do
      create_role(people.first, end_on: role_cutoff_date - 1)
      create_role(people.first, end_on: role_cutoff_date + 1)
      expect(subject).not_to include(people.first)
    end

    it "does not find people with active roles" do
      create_role(people.first, end_on: nil)
      expect(subject).not_to include(people.first)
    end

    it "does not find people that have both older roles AND current roles" do
      create_role(people.first, end_on: role_cutoff_date - 1)
      create_role(people.first, end_on: nil)

      expect(subject).not_to include(people.first)
    end

    it "finds people with participations at past events" do
      Event::Participation.create!(event: past_event, participant: people.first)
      expect(subject).to include(people.first)
    end

    it "does not find people with participations at future events" do
      Event::Participation.create!(event: future_event, participant: people.first)
      expect(subject).not_to include(people.first)
    end

    it "does not find people with participations at past and future events" do
      Event::Participation.create!(event: past_event, participant: people.first)
      Event::Participation.create!(event: future_event, participant: people.first)
      expect(subject).not_to include(people.first)
    end

    it "finds people with current_sign_in_at older than the cutoff time" do
      people.first.update!(current_sign_in_at: sign_in_cutoff_time - 1)
      expect(subject).to include(people.first)
    end

    it "does not find people with current_sign_in_at younger than the cutoff time" do
      people.first.update!(current_sign_in_at: sign_in_cutoff_time + 1)
      expect(subject).not_to include(people.first)
    end

    context "people with expired roles outside cutoff duration" do
      let(:people) do
        3.times.map {
          Fabricate(Group::BottomGroup::Member.name.to_sym,
            group: groups(:bottom_group_one_one),
            start_on: 11.months.ago,
            end_on: 10.months.ago).person
        }
      end

      before do
        expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_roles).and_return(9)
      end

      context "with people_manageds" do
        before do
          people.each do |p|
            p.manageds = [Fabricate(:person)]
          end
        end

        context "with current_sign_in_at outside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the future" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the past" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at nil" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

            people.each { |p| p.update!(current_sign_in_at: nil) }
          end

          it "does not finds them" do
            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at inside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end
      end

      context "without people_manageds" do
        context "with current_sign_in_at outside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 13.months.ago) }
          end

          it "finds them" do
            expect(subject).to match_array(people)
          end

          it "does not find them with event participation in the future" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end

          it "finds them with event participation in the past" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to match_array(people)
          end
        end

        context "with current_sign_in_at nil" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

            people.each { |p| p.update!(current_sign_in_at: nil) }
          end

          it "finds them" do
            expect(subject).to match_array(people)
          end
        end

        context "with current_sign_in_at inside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end
      end
    end

    context "people with expired roles inside cutoff duration" do
      let(:people) do
        3.times.map {
          Fabricate(Group::BottomGroup::Member.name.to_sym,
            group: groups(:bottom_group_one_one),
            start_on: 11.months.ago,
            end_on: 10.months.ago).person
        }
      end

      before do
        expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_roles).and_return(12)
      end

      context "with people_manageds" do
        before do
          people.each do |p|
            p.manageds = [Fabricate(:person)]
          end
        end

        context "with current_sign_in_at outside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 13.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the future" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the past" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at nil" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

            people.each { |p| p.update!(current_sign_in_at: nil) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at inside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end
      end

      context "without people_manageds" do
        context "with current_sign_in_at outside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 13.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the future" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end

          it "does not find them with event participation in the past" do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
            people.each do |p|
              Event::Participation.create!(event: event, person: p)
            end

            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at nil" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)

            people.each { |p| p.update!(current_sign_in_at: nil) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end

        context "with current_sign_in_at inside cutoff duration" do
          before do
            expect(Settings.people.cleanup_cutoff_duration).to receive(:regarding_current_sign_in_at).and_return(12)
            people.each { |p| p.update!(current_sign_in_at: 11.months.ago) }
          end

          it "does not find them" do
            expect(subject).to_not match_array(people)
          end
        end
      end
    end

    context "with people_manageds" do
      let(:people_with_roles) {
        3.times.map {
          Fabricate(Group::BottomGroup::Member.name.to_sym,
            group: groups(:bottom_group_one_one)).person
        }
      }
      let(:people_without_roles) { 3.times.map { Fabricate(:person) } }

      it "does not find people without any roles" do
        people_without_roles.each do |p|
          p.manageds += [Fabricate(:person)]
        end
        expect(subject).to_not match_array(people_without_roles)
      end

      it "does not find people with active roles" do
        people_with_roles.each do |p|
          p.manageds += [Fabricate(:person)]
        end
        expect(subject).to_not match_array(people_with_roles)
      end
    end
  end
end
