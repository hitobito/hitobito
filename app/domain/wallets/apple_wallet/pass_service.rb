# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module AppleWallet
    class PassService
      attr_reader :pass

      # Apple Wallet web service base path (appended to hostname in webServiceURL)
      WEB_SERVICE_PATH = "/wallets/apple/v1"

      # Apple Wallet standard image variants (filename => [width, height])
      ICON_VARIANTS = {
        "icon.png" => [29, 29],
        "icon@2x.png" => [58, 58]
      }.freeze

      THUMBNAIL_VARIANTS = {
        "thumbnail.png" => [90, 90],
        "thumbnail@2x.png" => [180, 180]
      }.freeze

      LOGO_VARIANTS = {
        "logo.png" => [160, 50],
        "logo@2x.png" => [320, 100]
      }.freeze

      # In a multi-tenant environment (multiple instances sharing the same
      # issuer_id), the wagon sets id_prefix_addition to a code block returning
      # a tenant-specific identifier so at runtime we ensure global uniqueness of
      # class and object IDs.
      class_attribute :id_prefix_addition

      attr_reader :config

      def initialize(pass_installation, client: PkpassGenerator.new, voided: false, config: Config)
        @pass = pass_installation.pass.decorate
        @pass_installation = pass_installation
        @client = client
        @voided = voided
        @config = config
      end

      # Generate a signed .pkpass file
      def generate_pass
        @client.create_pass(pass_data, pass_images, pass_strings)
      end

      # Pass data as hash for pass.json in the .pkpass bundle
      # Returns hash with formatVersion, passTypeIdentifier, serialNumber, teamIdentifier,
      # organizationName, description, colors, barcode, expirationDate, and style-specific fields
      # See: https://developer.apple.com/documentation/walletpasses/building_a_pass
      def pass_data
        base_pass_data.merge(pass_style_fields).compact
      end

      def serial_number
        [id_prefix, @pass_installation.id].join(".")
      end

      # Generate localized pass.strings files for all languages
      # Returns hash mapping filenames to string data (e.g. "pass.strings" => data,
      # "de.lproj/pass.strings" => data) with localization keys for field labels
      # See: https://developer.apple.com/documentation/walletpasses/building_a_pass
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

      private

      # Common fields shared by all pass styles
      def base_pass_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        {
          formatVersion: 1,
          passTypeIdentifier: config.pass_type_identifier,
          serialNumber: serial_number,
          teamIdentifier: config.team_identifier,
          organizationName: pass.definition.name,
          description: pass.definition.name,
          foregroundColor: hex_to_rgb(pass.text_colors[:text]),
          backgroundColor: hex_to_rgb(pass.definition.background_color),
          labelColor: hex_to_rgb(pass.text_colors[:label]),
          webServiceURL: web_service_url,
          authenticationToken: @pass_installation&.authentication_token,
          barcode: barcode,
          barcodes: [barcode],
          expirationDate: pass.valid_until&.end_of_day&.iso8601,
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
                  value: pass.valid_until.end_of_day.iso8601,
                  dateStyle: "PKDateStyleShort",
                  timeStyle: "PKDateStyleNone"
                 }
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

      # Generate the Apple Wallet web service URL for device registration and updates
      # Returns the base URL (e.g., https://example.com/wallets/apple/v1)
      # Uses Settings.application.protocol and .hostname (same logic as GoogleWallet)
      def web_service_url
        "#{Settings.application.protocol}://#{Settings.application.hostname}#{WEB_SERVICE_PATH}"
      end

      # In a multi-tenant environment (multiple instances sharing the same
      # pass_type_identifier), the wagon must override this method to include a
      # tenant-specific identifier to ensure global uniqueness of serial numbers.
      def id_prefix = ["hitobito", id_prefix_addition&.call].compact.join(".")

      def barcode
        {
          message: pass.qrcode_value,
          format: "PKBarcodeFormatQR",
          messageEncoding: "iso-8859-1",
          altText: pass.member_number.to_s
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

      def build_pass_strings
        <<~STRINGS
          "member_name_label" = "#{Pass.human_attribute_name(:member_name)}";
          "member_number_label" = "#{Pass.human_attribute_name(:member_number)}";
          "valid_until_label" = "#{Pass.human_attribute_name(:valid_until)}";
          "description_label" = "#{Pass.human_attribute_name(:description)}";
        STRINGS
      end

      # Build the images hash for the .pkpass bundle
      # Returns hash mapping filenames to binary image data (e.g. "icon.png" => data,
      # "logo.png" => data, "de.lproj/icon.png" => data). Apple requires icon.png, adding logo.png
      # is recommended.
      # See: https://developer.apple.com/documentation/walletpasses/building_a_pass
      def pass_images
        images = {}
        languages = Globalized.languages

        if languages.size > 1
          images.merge!(generate_localized_variants(languages))
        end

        images.merge!(generate_root_level_variants)
        images.merge(pass.wallet_data_provider.extra_apple_images)
      end

      # Generate localized variants for all languages
      def generate_localized_variants(languages)
        languages.each_with_object({}) do |lang, result|
          icon = pass.logo_icon(lang)
          result.merge!(generate_variants(icon, ICON_VARIANTS, "#{lang}.lproj/"))
          result.merge!(generate_variants(icon, THUMBNAIL_VARIANTS, "#{lang}.lproj/"))

          banner = pass.logo_banner(lang)
          result.merge!(generate_variants(banner, LOGO_VARIANTS, "#{lang}.lproj/"))
        end
      end

      # Generate root-level variants for fallback or single-language
      def generate_root_level_variants
        fallback_locale = @pass_installation.locale.to_sym
        icon = pass.logo_icon(fallback_locale)
        banner = pass.logo_banner(fallback_locale)

        generate_variants(icon, ICON_VARIANTS)
          .merge(generate_variants(icon, THUMBNAIL_VARIANTS))
          .merge(generate_variants(banner, LOGO_VARIANTS))
      end

      # Generate image variants for an attachment
      def generate_variants(attachment, variants, prefix = "")
        return {} unless attachment&.attached?

        variants.each_with_object({}) do |(filename, size), result|
          result["#{prefix}#{filename}"] =
            attachment.variant(resize_to_fit: size, format: :png).processed.download
        end
      end
    end
  end
end
