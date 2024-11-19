# frozen_string_literal: true

# Copyright (c) 2021-2024, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

require "spec_helper"

describe People::OneTimePassword do
  let(:bottom_member) { people(:bottom_member) }
  let(:generate_token) { described_class.generate_secret }
  let(:totp_authenticator) { subject.send(:authenticator) }

  subject { described_class.new(@secret, person: @person) }

  context "generate_secret" do
    it "returns random Base32" do
      expect(ROTP::Base32).to receive(:random)

      generate_token
    end
  end

  context "provisioning_uri" do
    it "returns uri with person email" do
      @secret = described_class.generate_secret
      @person = bottom_member

      expect(subject.provisioning_uri).to include(ERB::Util.url_encode(bottom_member.email))
    end
  end

  context "verify" do
    it "returns nil if input token incorrect" do
      @secret = generate_token

      expect(subject.verify(totp_authenticator.now + "1")).to eq(nil)
    end

    it "returns timestamp if input token correct" do
      @secret = generate_token

      expect(subject.verify(totp_authenticator.now)).to_not be_nil
    end

    it "returns timestamp if input token is correct but with spaces" do
      @secret = generate_token

      token = totp_authenticator.now.unpack("A3A3").join(" ")

      expect(subject.verify(token)).to_not be_nil
    end

    it "returns timestamp if input token is not expired" do
      @secret = generate_token

      current_time = Time.zone.now
      travel_to Time.zone.local(current_time.year, current_time.month, current_time.day, current_time.hour, current_time.min, 2)
      current_token = totp_authenticator.now

      travel 5.seconds
      expect(subject.verify(current_token)).to_not be_nil
    end

    it "returns timestamp if input token is expired since less than 15s" do
      @secret = generate_token

      current_time = Time.zone.now
      travel_to Time.zone.local(current_time.year, current_time.month, current_time.day, current_time.hour, current_time.min, 2)
      current_token = totp_authenticator.now

      travel 35.seconds
      expect(subject.verify(current_token)).to_not be_nil
    end

    it "returns timestamp if input token will be valid in less than 15s" do
      @secret = generate_token

      current_time = Time.zone.now
      travel_to Time.zone.local(current_time.year, current_time.month, current_time.day, current_time.hour, current_time.min, 2)
      current_token = totp_authenticator.now

      travel(-5.seconds)
      expect(subject.verify(current_token)).to_not be_nil
    end

    it "returns nil if input token expired more than 15s ago" do
      @secret = generate_token

      current_time = Time.zone.now
      travel_to Time.zone.local(current_time.year, current_time.month, current_time.day, current_time.hour, current_time.min, 2)
      current_token = totp_authenticator.now

      travel(-50.seconds)
      expect(subject.verify(current_token)).to eq(nil)
    end

    it "returns nil if input token will be valid in 15s or more" do
      @secret = generate_token

      current_time = Time.zone.now
      travel_to Time.zone.local(current_time.year, current_time.month, current_time.day, current_time.hour, current_time.min, 2)
      current_token = totp_authenticator.now

      travel(-25.seconds)
      expect(subject.verify(current_token)).to eq(nil)
    end
  end
end
