# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module GoogleWallet
    # Client for Google Wallet REST API
    #
    # Uses plain HTTP requests with JSON payloads instead of the
    # google-apis-walletobjects_v1 gem.
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

      @token_semaphore = Thread::Mutex.new

      class << self
        # Returns the shared OAuth2 bearer token, renewing it if necessary.
        # Token is cached at the class level so all instances (threads) reuse
        # the same credential, reducing token fetches to at most once per hour.
        # Access is serialized via a class-level mutex.
        def token(config = Config)
          @token_semaphore.synchronize { renew_expired_token(config) }
          @token
        end

        private

        # Fetches a fresh access token from Google using the service account
        # credentials in Config. Skips the fetch if the current token is still
        # valid. Stores the new token and its expiry in class-level variables.
        def renew_expired_token(config)
          return if @token_expires_at&.> Time.zone.now

          authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: StringIO.new(config.service_account_json),
            scope: SCOPES
          )
          authorizer.fetch_access_token!
          @token = authorizer.access_token
          @token_expires_at =
            Time.zone.now + authorizer.expires_in.to_i - RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS
        end
      end

      attr_reader :config

      def initialize(config = Config)
        @config = config
        raise "#{config::FILE_PATH} not found" unless config.exist?
      end

      # Create a pass class (template).
      # Returns existing class on 409 Conflict.
      def create_class(payload, type: :generic)
        paths = PASS_TYPES.fetch(type)
        request(:post, paths[:class_path], payload)
      rescue RestClient::Conflict
        request(:get, "#{paths[:class_path]}/#{payload[:id]}")
      end

      # Create or update a pass object (individual pass).
      # Updates existing object on 409 Conflict.
      def create_or_update_object(payload, type: :generic)
        paths = PASS_TYPES.fetch(type)
        request(:post, paths[:object_path], payload)
      rescue RestClient::Conflict
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

      # Executes an authenticated HTTP request against the Google Wallet API and
      # returns the parsed JSON response body as a symbolized hash.
      # Re-raises RestClient::BadRequest with an extracted error message from the
      # Google error envelope ({error: {message:, details:}}).
      def request(method, path, payload = nil)
        response = RestClient.send(method, *request_args(path, payload))
        JSON.parse(response.body, symbolize_names: true)
      rescue RestClient::Exception => e
        msg = extract_error_message(e.response)
        e.message += "\n#{msg}" if msg.present?
        raise
      end

      # Builds the positional argument list for RestClient.send.
      # GET/DELETE: [url, headers]
      # POST/PUT:   [url, json_body, headers]
      # nil payload is compacted out so RestClient receives the correct arity.
      def request_args(path, payload = nil)
        [
          url(path),
          payload&.to_json,
          headers
        ].compact
      end

      def url(path)
        "#{BASE_URL}/#{path}"
      end

      def headers
        {
          authorization: "Bearer #{token}",
          content_type: :json,
          accept: :json
        }
      end

      def token
        self.class.token(config)
      end

      # Builds a signed RS256 JWT for the "Save to Google Wallet" deep-link URL.
      # Google validates the JWT using the service account's public key to confirm
      # the issuer before showing the save prompt to the user.
      # The payload embeds the object reference under the correct key for the pass
      # type (genericObjects or eventTicketObjects).
      def build_save_jwt(object_id, type)
        jwt_key = (type == :event_ticket) ? :eventTicketObjects : :genericObjects
        payload = {
          iss: config.issuer_email || config.client_email,
          aud: "google",
          typ: "savetowallet",
          iat: Time.now.to_i,
          payload: {jwt_key => [{id: object_id}]}
        }
        private_key = OpenSSL::PKey::RSA.new(config.private_key)
        JWT.encode(payload, private_key, "RS256")
      end

      def extract_error_message(response)
        body = response&.body
        return nil if body.blank?
        format_google_error(body)
      end

      # Parses a Google API error response body and returns a human-readable
      # string. Expects the Google error envelope:
      #   { "error": { "message": "...", "details": [...] } }
      # Falls back to the raw truncated body if the envelope is absent or the
      # body is not valid JSON.
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
