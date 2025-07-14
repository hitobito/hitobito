# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::GuestLimiter do
  describe "#remaining" do
    context "for an event without waiting-list" do
      it "is zero, if there are no free places" do
        subject = described_class.new(free: 0, limit: 5, used: 0)
        expect(subject.remaining).to be 0
      end

      it "is the guest_limit, if there are enough places free" do
        subject = described_class.new(free: 10, limit: 3, used: 0)
        expect(subject.remaining).to be 3
      end

      it "is the minimum of guest_limit and free places" do
        subject = described_class.new(free: 2, limit: 3, used: 0)
        expect(subject.remaining).to be 2
      end

      it "is zero if the guest-limit has been reached" do
        subject = described_class.new(free: 10, limit: 2, used: 2)
        expect(subject.remaining).to be 0
      end

      it "shows the remaing guests up to the guest-limit" do
        subject = described_class.new(free: 10, limit: 5, used: 3)
        expect(subject.remaining).to be 2
      end
    end

    context "with a waiting-list" do
      it "is the guest-limit, if there are no free places" do
        subject = described_class.new(free: 0, limit: 5, used: 0, waiting_list: true)
        expect(subject.remaining).to be 5
      end

      it "is the guest_limit, if there are enough places free" do
        subject = described_class.new(free: 10, limit: 3, used: 0, waiting_list: true)
        expect(subject.remaining).to be 3
      end

      it "is the minimum of guest_limit and free places" do
        subject = described_class.new(free: 2, limit: 3, used: 0, waiting_list: true)
        expect(subject.remaining).to be 2
      end

      it "is zero if the guest-limit has been reached" do
        subject = described_class.new(free: 10, limit: 2, used: 2, waiting_list: true)
        expect(subject.remaining).to be 0
      end

      it "shows the remaing guests up to the guest-limit" do
        subject = described_class.new(free: 10, limit: 5, used: 3, waiting_list: true)
        expect(subject.remaining).to be 2
      end
    end
  end

  context "has a factory-method, which" do
    let!(:event) do
      event = events(:top_event)
      event.guest_limit = 2
      event.maximum_participants = 10
      event.waiting_list = false
      event.save
      event.reload

      event
    end

    let!(:participation) do
      Fabricate(
        :"Event::Role::Participant",
        participation: Fabricate(:event_participation, event: event)
      ).participation
    end

    let!(:guest_participation) do
      Fabricate(
        :"Event::Role::Participant",
        participation: Fabricate(
          :event_participation,
          event: event,
          participant: Fabricate(:event_guest, main_applicant: participation)
        )
      ).participation
    end

    subject { described_class.for(event, participation) }

    it "sets the configured guest limit" do
      expect(subject.limit).to eq 2 # configured
    end

    it "sets the free places" do
      expect(subject.free).to eq 8 # 10 - 1 participant - 1 guest
    end

    it "sets the used guest-spots" do
      expect(subject.used).to be 1 # the one 1 participant brings 1 guest
    end

    it "sets the waiting_list attribute" do
      expect(subject.waiting_list).to be_falsey
    end
  end
end
