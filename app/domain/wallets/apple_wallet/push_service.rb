# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module AppleWallet
    # Sends APNs push notifications to trigger pass updates on iOS devices.
    #
    # Flow: PushService -> APNs -> iOS device -> WebServiceController
    #
    # See: https://developer.apple.com/documentation/walletpasses/adding-a-web-service-to-update-passes
    class PushService
      APNS_PRODUCTION_URL = "https://api.push.apple.com"
      APNS_SANDBOX_URL = "https://api.sandbox.push.apple.com"

      def initialize(pass_installation)
        @pass_installation = pass_installation
      end

      # Send update notification to all registered devices
      def send_update_notification
        registrations = @pass_installation.device_registrations
        return if registrations.empty?

        registrations.find_each do |registration|
          send_push(registration.push_token)
        rescue => e
          registration.destroy if gone_response?(e)
          Rails.logger.warn("APNs push failed for token #{registration.push_token}: #{e.message}")
        end
      end

      private

      # Send an empty push notification via APNs HTTP/2
      #
      # Apple Wallet push notifications use:
      # - The P12 certificate (same as pass signing) for TLS client auth
      # - An empty JSON payload: {}
      # - Topic = pass type identifier
      def send_push(push_token)
        p12 = load_p12
        RestClient::Request.execute(
          method: :post,
          url: "#{apns_url}/3/device/#{push_token}",
          payload: "{}",
          headers: apns_headers,
          ssl_client_cert: p12.certificate,
          ssl_client_key: p12.key
        )
      end

      def apns_headers
        {
          "apns-topic" => Config.pass_type_identifier,
          "apns-push-type" => "background",
          "apns-priority" => "5"
        }
      end

      def load_p12
        OpenSSL::PKCS12.new(
          File.binread(Config.p12_certificate_path),
          Config.p12_password
        )
      end

      def apns_url
        Rails.env.production? ? APNS_PRODUCTION_URL : APNS_SANDBOX_URL
      end

      def gone_response?(error)
        error.is_a?(RestClient::Gone)
      end
    end
  end
end
