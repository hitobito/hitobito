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

      attr_reader :config

      def initialize(pass_installation, config = Config)
        @registrations = pass_installation.device_registrations
        @config = config
      end

      # Send update notification to all registered devices
      def send_update_notification
        @registrations.find_each do |registration|
          send_push(registration)
        end
      end

      private

      # Send an empty push notification via APNs HTTP/2
      #
      # Apple Wallet push notifications use:
      # - The PassKit certificate (same as pass signing) for TLS client auth
      # - An empty JSON payload: {}
      # - Topic = pass type identifier
      def send_push(registration)
        RestClient::Request.execute(
          method: :post,
          url: "#{apns_url}/3/device/#{registration.push_token}",
          payload: "{}",
          headers: apns_headers,
          ssl_client_cert: config.certificate,
          ssl_client_key: config.key
        )
      rescue => e
        registration.destroy if e.is_a?(RestClient::Gone)
        Rails.logger.warn("APNs push failed for token #{registration.push_token}: #{e.message}")
      end

      def apns_headers
        @apns_headers ||= {
          "apns-topic" => config.pass_type_identifier,
          "apns-push-type" => "background",
          "apns-priority" => "5"
        }
      end

      def apns_url
        @apns_url ||= Rails.env.production? ? APNS_PRODUCTION_URL : APNS_SANDBOX_URL
      end
    end
  end
end
