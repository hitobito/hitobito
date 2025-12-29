# frozen_string_literal: true

#  Copyright (c) 2025, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Sftp::ConfigContract do
  let(:valid_params) do
    {
      host: "sftp.example.com",
      port: 22,
      user: "testuser",
      password: "secret123",
      remote_path: "/uploads"
    }
  end

  subject { described_class.new.call(params) }

  context "with valid params" do
    let(:params) { valid_params }

    it { is_expected.to be_success }
  end

  context "with valid params using private_key instead of password" do
    let(:params) do
      valid_params.merge(password: nil, private_key: "-----BEGIN RSA PRIVATE KEY-----")
    end

    it { is_expected.to be_success }
  end

  context "with both password and private_key" do
    let(:params) do
      valid_params.merge(private_key: "-----BEGIN RSA PRIVATE KEY-----")
    end

    it { is_expected.to be_success }
  end

  context "with minimal required params" do
    let(:params) do
      {
        host: "sftp.example.com",
        user: "testuser",
        password: "secret123"
      }
    end

    it { is_expected.to be_success }
  end

  %i[host user].each do |field|
    context "when #{field} is missing" do
      let(:params) { valid_params.except(field) }

      it { is_expected.not_to be_success }

      it "has the correct error message" do
        expect(subject.errors[field]).to include("is missing")
      end
    end

    context "when #{field} is blank" do
      let(:params) { valid_params.merge(field => "") }

      it { is_expected.not_to be_success }

      it "has the correct error message" do
        expect(subject.errors[field]).to include("must be filled")
      end
    end
  end

  context "when port is negative" do
    let(:params) { valid_params.merge(port: -22) }

    it { is_expected.not_to be_success }
    it "has the correct error message" do
      expect(subject.errors[:port]).to include("must be greater than 0")
    end
  end

  context "when port is not a number" do
    let(:params) { valid_params.merge(port: "not_a_number") }

    it { is_expected.not_to be_success }
    it "has the correct error message" do
      expect(subject.errors[:port]).to include("must be an integer")
    end
  end

  context "when both password and private_key are blank" do
    let(:params) { valid_params.merge(password: "", private_key: "") }

    it { is_expected.not_to be_success }

    it "has the correct error message" do
      expect(subject.errors[:password]).to include("must be present if private_key is not given")
    end
  end
end
