# frozen_string_literal: true

#  copyright (c) 2024, schweizer alpen-club. this file is part of
#  hitobito and licensed under the affero general public license version 3
#  or later. see the copying file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::Membership::VerificationQrCode do
  let(:person) { people(:bottom_member) }
  let(:qr_code) { described_class.new(person).generate }

  context "with feature enabled" do
    before { allow(People::Membership::Verifier).to receive(:enabled?).and_return(true) }

    it "generates qr code for given person" do
      expect(person).to receive(:membership_verify_token).and_return("aSuperSweetToken42")
      expect(ENV).to receive(:fetch).with("RAILS_HOST_NAME", "localhost:3000").and_return("hitobito.example.com")

      bottom_member_qr_code = RQRCode::QRCode.new("http://hitobito.example.com/verify_membership/aSuperSweetToken42").to_s
      expect(qr_code.to_s).to eq(bottom_member_qr_code)
    end
  end

  it "raises error if verification feature not enabled" do
    expect do
      qr_code
    end.to raise_error(StandardError, "membership verification feature not enabled")
  end
end
