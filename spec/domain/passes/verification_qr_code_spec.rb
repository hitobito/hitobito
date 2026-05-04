# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Passes::VerificationQrCode do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:pass) { Fabricate(:pass, person: people(:top_leader), pass_definition: definition) }

  subject(:qr) { described_class.new(pass) }

  describe "#verify_url" do
    it "returns an absolute URL string" do
      expect(qr.verify_url).to be_a(String)
      expect(qr.verify_url).to start_with("http")
    end

    it "includes the pass verify_token" do
      expect(qr.verify_url).to include(pass.verify_token)
    end

    it "does not include the pass id" do
      expect(qr.verify_url).not_to include("/#{pass.id}/")
    end

    it "uses Settings.application.hostname for the host" do
      allow(Settings.application).to receive(:hostname).and_return("example.com")
      expect(qr.verify_url).to include("example.com")
    end
  end

  describe "#generate" do
    it "returns an RQRCode::QRCode instance" do
      expect(qr.generate).to be_a(RQRCode::QRCode)
    end
  end
end
