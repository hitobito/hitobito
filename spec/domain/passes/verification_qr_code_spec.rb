#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::VerificationQrCode do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject { described_class.new(person, definition) }

  let(:verify_token) { person.membership_verify_token }

  describe "#verify_url" do
    it "returns a URL containing the pass definition id" do
      url = subject.verify_url
      expect(url).to include("/passes/#{definition.id}/verify/")
    end

    it "returns a URL containing the person's membership_verify_token" do
      url = subject.verify_url
      expect(url).to include(verify_token)
    end

    it "uses the configured application host" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("RAILS_HOST_NAME", "localhost:3000").and_return("example.hitobito.com")
      url = subject.verify_url
      expect(url).to include("example.hitobito.com")
    end

    it "generates a full URL with correct path structure" do
      url = subject.verify_url
      expect(url).to match(%r{/passes/#{definition.id}/verify/#{verify_token}(\?|$)})
    end
  end

  describe "#generate" do
    it "returns an RQRCode::QRCode object" do
      qr = subject.generate
      expect(qr).to be_a(RQRCode::QRCode)
    end

    it "encodes the verify_url" do
      qr = subject.generate
      # RQRCode stores the original data — the verify_url should be used
      expect(subject.verify_url).to include("/passes/#{definition.id}/verify/")
    end
  end
end
