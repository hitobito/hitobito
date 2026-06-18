# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module GoogleWallet
    class PassService
      # Google Wallet image sizes (in pixels)
      LOGO_ICON_SIZE = [800, 800]
      LOGO_BANNER_SIZE = [1032, 336]

      # In a multi-tenant environment (multiple instances sharing the same
      # issuer_id), the wagon sets id_prefix_addition to a code block returning
      # a tenant-specific identifier so at runtime we ensure global uniqueness of
      # class and object IDs.
      class_attribute :id_prefix_addition

      attr_reader :config

      def initialize(pass_installation, client: nil, config: Config)
        @pass_installation = pass_installation
        @config = config
        @client = client || Client.new(config)
      end

      # Returns a signed JWT URL that opens "Save to Google Wallet" in the user's
      # browser or app. Assumes the GenericClass and GenericObject already exist on
      # Google's side (caller is responsible for syncing via create_or_update first).
      def save_url
        @client.generate_save_url(pass_object_id, type: pass_type)
      end

      # Ensures the pass template exists and pushes updated pass data to
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

      def id_prefix = [
        config.issuer_id,
        "hitobito",
        Settings.application.stage,
        id_prefix_addition&.call
      ].compact.join(".")

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
        logo = logo_icon_uri
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
      def generic_object # rubocop:disable Metrics/AbcSize
        {
          id: pass_object_id,
          classId: class_id,
          state: "ACTIVE",
          cardTitle: localized_string { pass.definition.name },
          header: localized_string { pass.member_name },
          barcode: qr_barcode,
          textModulesData: generic_text_modules,
          hexBackgroundColor: pass.definition.background_color,
          heroImage: logo_banner_uri,
          logo: logo_icon_uri,
          validTimeInterval: valid_time_interval
        }.compact
      end

      def generic_text_modules
        base_modules + extra_text_modules
      end

      def base_modules # rubocop:disable Metrics/AbcSize
        modules = [
          {id: "member_name",
           localizedHeader: localized_string { Pass.human_attribute_name(:member_name) },
           body: pass.member_name},
          {id: "member_number",
           localizedHeader: localized_string {
             Pass.human_attribute_name(:member_number)
           },
           body: pass.member_number}
        ]
        modules << valid_until_module if pass.valid_until.present?
        modules << description_module if pass.definition.description.present?
        modules
      end

      def description_module
        {id: "description",
         localizedHeader: localized_string { Pass.human_attribute_name(:description) },
         localizedBody: localized_string { pass.definition.description }}
      end

      def valid_until_module
        {id: "valid_until",
         localizedHeader: localized_string { Pass.human_attribute_name(:valid_until) },
         localizedBody: localized_string { I18n.l(pass.valid_until) }}
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

      # Builds a Google Wallet LocalizedString covering all configured locales.
      # Uses I18n.with_locale so translatable values are resolved per locale.
      # default_locale becomes defaultValue (pass_installation.locale for consistency);
      # remaining Settings.application.languages keys become translatedValues.
      def localized_string
        default_lang = @pass_installation.locale.to_sym
        other_locales = Settings.application.languages.keys.map(&:to_sym) - [default_lang]
        {
          defaultValue: {language: default_lang.to_s, value: I18n.with_locale(default_lang) {
            yield
          }},
          translatedValues: other_locales.map { |locale|
            {language: locale.to_s, value: I18n.with_locale(locale) { yield }}
          }.presence
        }.compact
      end

      def valid_time_interval
        {
          start: {date: pass.valid_from.beginning_of_day.iso8601},
          end: pass.valid_until ? {date: pass.valid_until.end_of_day.iso8601} : nil
        }.compact.presence
      end

      # Wraps a URL in the Google Wallet image URI structure.
      # Returns nil (so callers can use .compact) when the URL is blank, not an
      # absolute HTTP(S) URL, or points to localhost (unreachable by Google servers).
      def image_uri(url)
        return nil if url.blank? || !url.start_with?("http") || url.include?("localhost")

        {sourceUri: {uri: url}}
      end

      def logo_icon_uri
        variant_url(pass.logo_icon(@pass_installation.locale.to_sym), LOGO_ICON_SIZE)
      end

      def logo_banner_uri
        variant_url(pass.logo_banner(@pass_installation.locale.to_sym), LOGO_BANNER_SIZE)
      end

      private

      def variant_url(attachment, size)
        return nil unless attachment&.attached?

        url = Rails.application.routes.url_helpers.rails_representation_url(
          attachment.variant(resize_to_fit: size, format: :png),
          protocol: Settings.application.protocol,
          host: Settings.application.hostname,
          only_path: false
        )

        return nil unless url
        image_uri(url)
      end
    end
  end
end
