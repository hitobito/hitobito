# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module GoogleWallet
    class PassService
      def initialize(pass_installation, client: Client.new)
        @pass_installation = pass_installation
        @client = client
      end

      # Ensures the GenericClass template exists on Google Wallet, then creates or
      # updates the person's GenericObject, and returns a signed JWT URL that opens
      # "Save to Google Wallet" in the user's browser or app.
      # Called by the controller when a person first adds the pass.
      def save_url
        @client.create_class(pass_class, type: pass_type)
        @client.create_or_update_object(pass_object, type: pass_type)
        @client.generate_save_url(pass_object_id, type: pass_type)
      end

      # Ensures the GenericClass template exists and pushes updated pass data to
      # Google Wallet without generating a URL. Called by PassSynchronizer on state
      # changes (e.g. expiry, renewal).
      def create_or_update
        @client.create_class(pass_class, type: pass_type)
        @client.create_or_update_object(pass_object, type: pass_type)
      end

      # Revoke a pass by setting Google object state to INACTIVE.
      # No Class update is needed; only the minimal object payload is sent.
      # Called by PassSynchronizer when a Pass transitions to :revoked.
      def revoke
        @client.create_or_update_object(
          {id: pass_object_id, state: "INACTIVE"},
          type: pass_type
        )
      end

      def pass
        @pass ||= @pass_installation.pass.decorate
      end

      private

      # Currently always :generic. Event ticket support planned for future phase.
      def pass_type = :generic

      def id_prefix = [Config.issuer_id, "hitobito"].join(".")

      # Identifies the pass template shared by all holders of the same PassDefinition.
      def class_id
        [
          id_prefix,
          "class",
          pass.pass_definition_id
        ].join(".")
      end

      # Identifies a single person's pass in Google Wallet.
      def pass_object_id
        [
          id_prefix,
          "pass",
          pass.id,
          @pass_installation.id
        ].join(".")
      end

      def pass_class = generic_class

      def pass_object = generic_object

      # Builds the GenericClass payload (the shared pass template for a PassDefinition).
      # The Class must exist before any GenericObject can reference it via classId.
      # API reference: https://developers.google.com/wallet/reference/rest/v1/genericclass
      def generic_class
        logo = image_uri(pass.logo_url)
        {
          id: class_id,
          issuerName: pass.definition.name,
          reviewStatus: "UNDER_REVIEW",
          multipleDevicesAndHoldersAllowedStatus: "MULTIPLE_HOLDERS",
          securityAnimation: {animationType: "FOIL_SHIMMER"},
          imageModulesData: logo ? [{mainImage: logo}] : nil,
          linksModuleData: nil
        }.compact
      end

      # Builds the GenericObject payload (the individual pass for one person).
      # All nil values are removed via .compact before sending to the API.
      # API reference: https://developers.google.com/wallet/reference/rest/v1/genericobject
      def generic_object
        {
          id: pass_object_id,
          classId: class_id,
          state: "ACTIVE",
          cardTitle: {defaultValue: {language: I18n.locale.to_s, value: pass.definition.name}},
          header: {defaultValue: {language: I18n.locale.to_s, value: pass.member_name}},
          barcode: qr_barcode,
          textModulesData: generic_text_modules,
          hexBackgroundColor: pass.definition.background_color,
          heroImage: image_uri(pass.logo_url),
          logo: image_uri(pass.logo_url),
          validTimeInterval: valid_time_interval
        }.compact
      end

      def generic_text_modules
        base_modules + extra_text_modules
      end

      def base_modules
        modules = [
          {id: "member_name", header: I18n.t("wallets.pass.member_name"),
           body: pass.member_name},
          {id: "member_number", header: I18n.t("wallets.pass.member_number"),
           body: pass.member_number},
          {id: "valid_until", header: I18n.t("wallets.pass.valid_until"),
           body: pass.valid_until ? I18n.l(pass.valid_until) : ""}
        ]
        modules << description_module if pass.definition.description.present?
        modules
      end

      def description_module
        {id: "description", header: I18n.t("wallets.pass.description"),
         body: pass.definition.description}
      end

      # Additional text modules from the template's WalletDataProvider.
      # Wagon-registered providers can return extra modules here
      # (e.g., SAC adds membership_years, section name).
      def extra_text_modules
        pass.wallet_data_provider.extra_google_text_modules
      end

      def qr_barcode
        {
          type: "QR_CODE",
          value: pass.qrcode_value,
          alternateText: pass.member_number
        }
      end

      def valid_time_interval
        {
          start: {date: pass.valid_from.beginning_of_day.iso8601},
          end: pass.valid_until ? {date: pass.valid_until.end_of_day.iso8601} : nil
        }.compact.presence
      end

      def image_uri(url)
        return nil if url.blank? || !url.start_with?("http") || url.include?("localhost")

        {sourceUri: {uri: url}}
      end
    end
  end
end
