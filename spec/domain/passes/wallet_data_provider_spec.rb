#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::WalletDataProvider do
  let(:person) { Struct.new(:id, :full_name).new(42, "Max Muster") }
  let(:pass) { Struct.new(:person).new(person) }

  subject(:provider) { described_class.new(pass) }

  describe "#member_number" do
    it "returns a zero-padded person id" do
      expect(provider.member_number).to eq("00000042")
    end
  end

  describe "#member_name" do
    it "returns the person's full_name" do
      expect(provider.member_name).to eq("Max Muster")
    end
  end

  describe "#extra_google_text_modules" do
    it "returns an empty array" do
      expect(provider.extra_google_text_modules).to eq([])
    end
  end

  describe "#extra_apple_fields" do
    it "returns an empty hash" do
      expect(provider.extra_apple_fields).to eq({})
    end
  end

  describe "#extra_apple_images" do
    it "returns an empty hash" do
      expect(provider.extra_apple_images).to eq({})
    end
  end
end
