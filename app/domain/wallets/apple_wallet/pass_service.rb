# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module AppleWallet
    class PassService
      attr_reader :pass

      def initialize(pass_installation, client: PkpassGenerator.new, voided: false)
        @pass = pass_installation.pass.decorate
        @pass_installation = pass_installation
        @client = client
        @voided = voided
      end

      # Generate a signed .pkpass file
      # @return [String] Binary .pkpass data
      def generate_pass
        @client.create_pass(pass_data, pass_images)
      end

      # Pass data as hash (also used by WebServiceController to serve updates)
      def pass_data
        base_pass_data.merge(pass_style_fields).compact
      end

      private

      # Common fields shared by all pass styles
      def base_pass_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        {
          formatVersion: 1,
          passTypeIdentifier: Config.pass_type_identifier,
          serialNumber: serial_number,
          teamIdentifier: Config.team_identifier,
          organizationName: pass.definition.name,
          description: pass.definition.name,
          foregroundColor: "rgb(255, 255, 255)",
          backgroundColor: hex_to_rgb(pass.definition.background_color),
          labelColor: "rgb(255, 255, 255)",
          webServiceURL: Config.web_service_url,
          authenticationToken: @pass_installation&.authentication_token,
          barcode: barcode,
          barcodes: [barcode],
          expirationDate: pass.valid_until&.iso8601,
          voided: @voided
        }
      end

      # Currently always generic. Event ticket style planned for future phase.
      def pass_style_fields
        generic_style
      end

      # --- Generic style (group membership passes) ---

      def generic_style # rubocop:disable Metrics/MethodLength
        base = {
          generic: {
            primaryFields: [
              {key: "member_name",
               label: I18n.t("wallets.apple.member_name"),
               value: pass.member_name}
            ],
            secondaryFields: [
              {key: "member_number",
               label: I18n.t("wallets.pass.member_number"),
               value: pass.member_number}
            ],
            auxiliaryFields: [
              (if pass.valid_until
                 {key: "valid_until",
                  label: I18n.t("wallets.pass.valid_until"),
                  value: pass.valid_until&.iso8601,
                  dateStyle: "PKDateStyleShort"}
               end)
            ].compact,
            backFields: description_back_fields
          }
        }
        merge_extra_apple_fields(base)
      end

      # Merge additional Apple fields from the template's WalletDataProvider.
      # Wagon-registered providers can add fields to any field group
      # (primaryFields, secondaryFields, auxiliaryFields, backFields).
      def merge_extra_apple_fields(base)
        extras = pass.wallet_data_provider.extra_apple_fields
        extras.each do |field_group, fields|
          base[:generic][field_group] ||= []
          base[:generic][field_group].concat(Array(fields))
        end
        base
      end

      # --- Shared helpers ---

      # In a multi-tenant environment (multiple instances sharing the same
      # pass_type_identifier), the wagon must override this method to include a
      # tenant-specific identifier to ensure global uniqueness of serial numbers.
      def id_prefix = "hitobito"

      def serial_number
        [id_prefix, @pass_installation.id].join(".")
      end

      def barcode
        {
          message: pass.qrcode_value,
          format: "PKBarcodeFormatQR",
          messageEncoding: "iso-8859-1",
          altText: pass.member_number
        }
      end

      # Description shown on the back of the pass (flip side).
      def description_back_fields
        return [] if pass.definition.description.blank?

        [{key: "description",
          label: I18n.t("wallets.pass.description"),
          value: pass.definition.description}]
      end

      # Convert hex color (#0066cc) to Apple's rgb() format.
      def hex_to_rgb(hex)
        r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
        "rgb(#{r}, #{g}, #{b})"
      end

      # Build the images hash for the .pkpass bundle.
      # Apple requires icon.png; logo.png is recommended.
      def pass_images
        images = {}
        data = pass.logo_blob
        if data
          images["icon.png"] = data
          images["logo.png"] = data
        end
        images.merge(pass.wallet_data_provider.extra_apple_images)
      end
    end
  end
end
