#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::AppleWallet::PushService do
  let(:person) { people(:top_leader) }
  let(:definition) do
    Fabricate(:pass_definition,
      owner: groups(:top_layer),
      name: "Test Pass",
      background_color: "#003366")
  end
  let(:pass) do
    Fabricate(:pass, person: person, pass_definition: definition,
      state: :eligible, valid_from: Date.current)
  end
  let(:installation) do
    Fabricate(:wallets_pass_installation, pass: pass, wallet_type: :apple)
  end

  let(:test_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:test_cert) do
    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.new([["CN", "Test"]])
    cert.issuer = cert.subject
    cert.not_before = Time.current
    cert.not_after = Time.current + 3600
    cert.public_key = test_key.public_key
    cert.serial = 1
    cert.sign(test_key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  let(:mock_config) do
    class_double(Wallets::AppleWallet::Config,
      pass_type_identifier: "pass.com.example.test",
      certificate: test_cert,
      key: test_key)
  end

  subject(:push_service) { described_class.new(installation, mock_config) }

  describe "#send_update_notification" do
    context "with no device registrations" do
      it "does nothing" do
        expect(RestClient::Request).not_to receive(:execute)
        push_service.send_update_notification
      end
    end

    context "with one device registration" do
      let!(:registration) do
        Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-1",
          push_token: "abc123token")
      end

      it "sends push notification to the device" do
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/abc123token")
          .to_return(status: 200, body: "")

        push_service.send_update_notification

        expect(WebMock).to have_requested(:post, "https://api.sandbox.push.apple.com/3/device/abc123token")
          .with(
            body: "{}",
            headers: {
              "apns-topic" => "pass.com.example.test",
              "apns-push-type" => "background",
              "apns-priority" => "5"
            }
          )
      end

      it "uses production URL in production environment" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        stub_request(:post, "https://api.push.apple.com/3/device/abc123token")
          .to_return(status: 200, body: "")

        push_service.send_update_notification

        expect(WebMock).to have_requested(:post, "https://api.push.apple.com/3/device/abc123token")
      end
    end

    context "with multiple device registrations" do
      let!(:registration1) do
        Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-1",
          push_token: "token-1")
      end
      let!(:registration2) do
        Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-2",
          push_token: "token-2")
      end

      it "sends push to all registered devices" do
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/token-1")
          .to_return(status: 200, body: "")
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/token-2")
          .to_return(status: 200, body: "")

        push_service.send_update_notification

        expect(WebMock).to have_requested(:post, "https://api.sandbox.push.apple.com/3/device/token-1")
        expect(WebMock).to have_requested(:post, "https://api.sandbox.push.apple.com/3/device/token-2")
      end
    end

    context "when APNs returns 410 Gone (invalid token)" do
      let!(:registration) do
        Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-1",
          push_token: "invalid-token")
      end

      it "deletes the device registration" do
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/invalid-token")
          .to_return(status: 410, body: '{"reason":"Unregistered"}')

        expect {
          push_service.send_update_notification
        }.to change(Wallets::AppleWallet::DeviceRegistration, :count).by(-1)
      end

      it "logs a warning" do
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/invalid-token")
          .to_return(status: 410, body: '{"reason":"Unregistered"}')

        allow(Rails.logger).to receive(:warn).and_call_original

        push_service.send_update_notification

        expect(Rails.logger).to have_received(:warn).with(/APNs push failed for token invalid-token/)
      end
    end

    context "when APNs returns other errors" do
      let!(:registration) do
        Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-1",
          push_token: "error-token")
      end

      it "logs the error but does not delete registration" do
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/error-token")
          .to_return(status: 500, body: '{"reason":"InternalServerError"}')

        allow(Rails.logger).to receive(:warn).and_call_original

        expect {
          push_service.send_update_notification
        }.not_to change(Wallets::AppleWallet::DeviceRegistration, :count)

        expect(Rails.logger).to have_received(:warn).with(/APNs push failed for token error-token/)
      end

      it "continues processing remaining registrations after error" do
        _other_reg = Fabricate(:wallets_apple_device_registration,
          pass_installation: installation,
          device_library_identifier: "device-2",
          push_token: "good-token")

        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/error-token")
          .to_return(status: 500, body: '{"reason":"InternalServerError"}')
        stub_request(:post, "https://api.sandbox.push.apple.com/3/device/good-token")
          .to_return(status: 200, body: "")

        push_service.send_update_notification

        expect(WebMock).to have_requested(:post, "https://api.sandbox.push.apple.com/3/device/good-token")
      end
    end
  end
end
