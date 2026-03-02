#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module GoogleWallet
    # Client for Google Wallet REST API
    #
    # Uses plain HTTP requests with JSON payloads instead of the
    # google-apis-walletobjects_v1 gem. Modeled after Invoices::Abacus::Client.
    #
    # Supports pass types via the `type` parameter:
    #   :generic         -> genericClass / genericObject   (group membership passes)
    #   :event_ticket    -> eventTicketClass / eventTicketObject (future: event passes)
    #
    # API Reference: https://developers.google.com/wallet/reference/rest
    class Client
      BASE_URL = "https://walletobjects.googleapis.com/walletobjects/v1"
      SAVE_URL_PREFIX = "https://pay.google.com/gp/v/save"
      SCOPES = ["https://www.googleapis.com/auth/wallet_object.issuer"].freeze
      RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS = 30

      PASS_TYPES = {
        generic: {class_path: "genericClass", object_path: "genericObject"},
        event_ticket: {class_path: "eventTicketClass", object_path: "eventTicketObject"}
      }.freeze

      def initialize
        raise "#{Config::FILE_PATH} not found" unless Config.exist?
        @token_semaphore = Thread::Mutex.new
      end

      # Create a pass class (template).
      # Returns existing class on 409 Conflict.
      def create_class(payload, type: :generic)
        paths = PASS_TYPES.fetch(type)
        request(:post, paths[:class_path], payload)
      rescue Faraday::ConflictError
        request(:get, "#{paths[:class_path]}/#{payload[:id]}")
      end

      # Create or update a pass object (individual pass).
      # Updates existing object on 409 Conflict.
      def create_or_update_object(payload, type: :generic)
        paths = PASS_TYPES.fetch(type)
        request(:post, paths[:object_path], payload)
      rescue Faraday::ConflictError
        request(:put, "#{paths[:object_path]}/#{payload[:id]}", payload)
      end

      # Retrieve an existing pass object.
      def get_object(object_id, type: :generic)
        paths = PASS_TYPES.fetch(type)
        request(:get, "#{paths[:object_path]}/#{object_id}")
      end

      # Generate a "Save to Google Wallet" URL.
      def generate_save_url(object_id, type: :generic)
        jwt = build_save_jwt(object_id, type)
        "#{SAVE_URL_PREFIX}/#{jwt}"
      end

      private

      def request(method, path, payload = nil)
        response = connection.send(method, path) do |req|
          req.body = payload.to_json if payload
        end
        JSON.parse(response.body, symbolize_names: true)
      rescue Faraday::BadRequestError => e
        raise Faraday::BadRequestError.new(extract_error_message(e.response), e.response)
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :raise_error
          f.headers["Authorization"] = "Bearer #{token}"
          f.headers["Content-Type"] = "application/json"
          f.headers["Accept"] = "application/json"
        end
      end

      # OAuth2 token management (thread-safe, auto-renewing)
      def token
        @token_semaphore.synchronize { renew_expired_token }
        @token
      end

      def renew_expired_token
        return if @token_expires_at.present? && @token_expires_at > Time.zone.now

        authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(Config.service_account_json),
          scope: SCOPES
        )
        authorizer.fetch_access_token!
        @token = authorizer.access_token
        @token_expires_at =
          Time.zone.now + authorizer.expires_in.to_i - RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS
      end

      # JWT for save-to-wallet URL
      def build_save_jwt(object_id, type)
        jwt_key = (type == :event_ticket) ? :eventTicketObjects : :genericObjects
        payload = {
          iss: Config.issuer_email || Config.client_email,
          aud: "google",
          typ: "savetowallet",
          iat: Time.now.to_i,
          payload: {jwt_key => [{id: object_id}]}
        }
        private_key = OpenSSL::PKey::RSA.new(Config.private_key)
        JWT.encode(payload, private_key, "RS256")
      end

      def extract_error_message(response)
        body = response&.dig(:body)
        return nil if body.blank?
        format_google_error(body)
      end

      def format_google_error(body)
        error = JSON.parse(body).dig("error")
        return body.to_s.truncate(1000) unless error
        details = error["details"]&.map { |d| d.inspect }&.join(", ")
        [error["message"], details].compact.join(" | details: ")
      rescue JSON::ParserError
        body.to_s.truncate(1000)
      end
    end
  end
end
