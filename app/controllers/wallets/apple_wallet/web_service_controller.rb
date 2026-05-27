#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module AppleWallet
    # Apple Wallet Web Service API
    #
    # iOS calls these endpoints automatically when a pass with webServiceURL
    # is installed, updated, or removed.
    #
    # See: https://developer.apple.com/documentation/walletpasses/adding-a-web-service-to-update-passes
    class WebServiceController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_authorization_check
      skip_before_action :authenticate_person!

      rescue_from ActionDispatch::Http::Parameters::ParseError do
        head :ok
      end

      before_action :authenticate_pass!, except: [:updatable_passes, :log_message]

      # POST /v1/devices/:device_id/registrations/:pass_type_id/:serial
      def register_device
        registration = @pass_installation.device_registrations.find_or_initialize_by(
          device_library_identifier: params[:device_id]
        )

        registration.push_token = parsed_push_token
        registration.save!
        registration.previously_new_record? ? head(:created) : head(:ok)
      end

      # DELETE /v1/devices/:device_id/registrations/:pass_type_id/:serial
      def unregister_device
        registration = @pass_installation.device_registrations.find_by(
          device_library_identifier: params[:device_id]
        )
        registration&.destroy
        head :ok
      end

      # GET /v1/devices/:device_id/registrations/:pass_type_id?passesUpdatedSince=...
      def updatable_passes
        passes = installations_for_device
        passes = filter_updated_since(passes) if params[:passesUpdatedSince].present?

        return head(:no_content) if passes.empty?

        render json: {
          serialNumbers: passes.map { |p| PassService.new(p).serial_number },
          lastUpdated: passes.maximum(:updated_at).to_i.to_s
        }
      end

      # GET /v1/passes/:pass_type_id/:serial
      def send_updated_pass
        service = PassService.new(@pass_installation, voided: @pass_installation.revoked?)

        send_data service.generate_pass,
          type: "application/vnd.apple.pkpass",
          disposition: "inline"
      end

      # POST /v1/log
      def log_message
        log_data = parse_json_body
        Array(log_data&.fetch("logs", nil)).each do |msg|
          Rails.logger.info("[AppleWallet] #{msg}")
        end
        head :ok
      end

      private

      def installations_for_device
        Wallets::PassInstallation.apple
          .joins(:device_registrations)
          .where(wallets_apple_device_registrations: {
            device_library_identifier: params[:device_id]
          })
      end

      def filter_updated_since(passes)
        since = Time.zone.at(params[:passesUpdatedSince].to_i)
        passes.where("wallets_pass_installations.updated_at > ?", since)
      end

      def authenticate_pass!
        auth_header = request.headers["Authorization"]
        unless auth_header&.start_with?("ApplePass ")
          head :unauthorized
          return
        end

        token = auth_header.delete_prefix("ApplePass ")
        @pass_installation = Wallets::PassInstallation.apple.find_by(
          id: params[:serial].split(".").last,
          authentication_token: token
        )

        head :unauthorized unless @pass_installation
      end

      def parsed_push_token
        body = parse_json_body
        body&.fetch("pushToken", nil)
      end

      def parse_json_body
        body = request.body.read
        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
