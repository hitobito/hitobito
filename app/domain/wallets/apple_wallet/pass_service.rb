# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module AppleWallet
    class PassService
      attr_reader :pass

      # In a multi-tenant environment (multiple instances sharing the same
      # issuer_id), the wagon sets id_prefix_addition to a code block returning
      # a tenant-specific identifier so at runtime we ensure global uniqueness of
      # class and object IDs.
      class_attribute :id_prefix_addition

      def initialize(pass_installation, client: PkpassGenerator.new, voided: false)
        @pass = pass_installation.pass.decorate
        @pass_installation = pass_installation
        @client = client
        @voided = voided
      end

      # Generate a signed .pkpass file
      # @return [String] Binary .pkpass data
      def generate_pass
        @client.create_pass(pass_data, pass_images, pass_strings)
      end

      # Pass data as hash (also used by WebServiceController to serve updates)
      def pass_data
        base_pass_data.merge(pass_style_fields).compact
      end

      def serial_number
        [id_prefix, @pass_installation.id].join(".")
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
          foregroundColor: hex_to_rgb(pass.text_colors[:text]),
          backgroundColor: hex_to_rgb(pass.definition.background_color),
          labelColor: hex_to_rgb(pass.text_colors[:label]),
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
               label: "member_name_label",
               value: pass.member_name}
            ],
            secondaryFields: [
              {key: "member_number",
               label: "member_number_label",
               value: pass.member_number}
            ],
            auxiliaryFields: [
              (if pass.valid_until
                 {key: "valid_until",
                  label: "valid_until_label",
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
      def id_prefix = ["hitobito", id_prefix_addition&.call].compact.join(".")

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
          label: "description_label",
          value: pass.definition.description}]
      end

      # Convert hex color (#0066cc) to Apple's rgb() format.
      def hex_to_rgb(hex)
        r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
        "rgb(#{r}, #{g}, #{b})"
      end

      # Generate localized pass.strings files for all languages.
      def pass_strings
        strings = {}

        # Lokalisierte pass.strings für alle App-Sprachen
        Globalized.languages.each do |lang|
          I18n.with_locale(lang) do
            strings["#{lang}.lproj/pass.strings"] = build_pass_strings
          end
        end

        # Root-Level-Fallback: pass_installation.locale
        I18n.with_locale(@pass_installation.locale.to_sym) do
          strings["pass.strings"] = build_pass_strings
        end

        strings
      end

      def build_pass_strings
        <<~STRINGS
          "member_name_label" = "#{I18n.t("wallets.apple.member_name")}";
          "member_number_label" = "#{I18n.t("wallets.pass.member_number")}";
          "valid_until_label" = "#{I18n.t("wallets.pass.valid_until")}";
          "description_label" = "#{I18n.t("wallets.pass.description")}";
          "org_name" = "#{pass.definition.name}";
        STRINGS
      end

      # Build the images hash for the .pkpass bundle.
      # Apple requires icon.png; logo.png is recommended.
      def pass_images
        images = {}
        languages = Globalized.languages

        if languages.size > 1
          # Mehrsprachig: Bilder in .lproj-Ordnern + Root-Level-Fallback
          languages.each do |lang|
            attachment = pass.definition.logo_icon(lang)
            images["#{lang}.lproj/icon.png"] = attachment.variant(resize_to_fill: [29, 29], format: :png).download
            images["#{lang}.lproj/icon@2x.png"] = attachment.variant(resize_to_fill: [58, 58], format: :png).download
            images["#{lang}.lproj/thumbnail.png"] = attachment.variant(resize_to_fill: [90, 90], format: :png).download
            images["#{lang}.lproj/thumbnail@2x.png"] = attachment.variant(resize_to_fill: [180, 180], format: :png).download

            banner = pass.definition.logo_banner(lang)
            images["#{lang}.lproj/logo.png"] = banner.variant(resize_to_fit: [160, 50], format: :png).download
            images["#{lang}.lproj/logo@2x.png"] = banner.variant(resize_to_fit: [320, 100], format: :png).download
          end

          # Root-Level-Fallback: pass_installation.locale
          fallback_locale = @pass_installation.locale.to_sym
          attachment = pass.definition.logo_icon(fallback_locale)
          images["icon.png"] = attachment.variant(resize_to_fill: [29, 29], format: :png).download
          images["icon@2x.png"] = attachment.variant(resize_to_fill: [58, 58], format: :png).download
          images["thumbnail.png"] = attachment.variant(resize_to_fill: [90, 90], format: :png).download
          images["thumbnail@2x.png"] = attachment.variant(resize_to_fill: [180, 180], format: :png).download

          banner = pass.definition.logo_banner(fallback_locale)
          images["logo.png"] = banner.variant(resize_to_fit: [160, 50], format: :png).download
          images["logo@2x.png"] = banner.variant(resize_to_fit: [320, 100], format: :png).download
        else
          # Einsprachig: Bilder direkt im Root
          attachment = pass.definition.logo_icon
          images["icon.png"] = attachment.variant(resize_to_fill: [29, 29], format: :png).download
          images["icon@2x.png"] = attachment.variant(resize_to_fill: [58, 58], format: :png).download
          images["thumbnail.png"] = attachment.variant(resize_to_fill: [90, 90], format: :png).download
          images["thumbnail@2x.png"] = attachment.variant(resize_to_fill: [180, 180], format: :png).download

          banner = pass.definition.logo_banner
          images["logo.png"] = banner.variant(resize_to_fit: [160, 50], format: :png).download
          images["logo@2x.png"] = banner.variant(resize_to_fit: [320, 100], format: :png).download
        end

        images.merge(pass.wallet_data_provider.extra_apple_images)
      end
    end
  end
end
