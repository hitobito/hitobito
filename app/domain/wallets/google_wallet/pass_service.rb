#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module GoogleWallet
    class PassService
      def pass = @pass_installation.pass


      def initialize(pass_installation, client: Client.new)
        @pass_installation = pass_installation
        @client = client
      end

      def save_url
        @client.create_class(pass_class, type: pass_type)
        @client.create_or_update_object(pass_object, type: pass_type)
        @client.generate_save_url(pass_object_id, type: pass_type)
      end

      def create_or_update
        @client.create_class(pass_class, type: pass_type)
        @client.create_or_update_object(pass_object, type: pass_type)
      end

      # Revoke a pass by setting Google object state to INACTIVE.
      def revoke
        @client.create_or_update_object(
          {id: pass_object_id, state: "INACTIVE"},
          type: pass_type
        )
      end

      private

      # Currently always :generic. Event ticket support planned for future phase.
      def pass_type = :generic

      def class_id
        "#{Config.issuer_id}.pass_class_#{pass.definition.id}"
      end

      def pass_object_id
        "#{Config.issuer_id}.pass_#{@pass_installation.wallet_identifier}"
      end

      def pass_class = generic_class

      def pass_object = generic_object

      # --- Generic pass (group membership) ---

      def generic_class
        logo = logo_image_uri
        {
          id: class_id,
          issuerName: pass.definition.name,
          reviewStatus: "UNDER_REVIEW",
          multipleDevicesAndHoldersAllowedStatus: "MULTIPLE_HOLDERS",
          imageModulesData: logo ? [{mainImage: logo}] : nil,
          linksModuleData: nil
        }.compact
      end

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
          heroImage: logo_image_uri,
          logo: logo_image_uri,
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
        if pass.definition.description.present?
          modules << {id: "description", header: I18n.t("wallets.pass.description"),
                      body: pass.definition.description}
        end
        modules
      end

      # Additional text modules from the template's WalletDataProvider.
      # Wagon-registered providers can return extra modules here
      # (e.g., SAC adds membership_years, section name).
      def extra_text_modules
        pass.wallet_data_provider.extra_google_text_modules
      end

      # --- Shared helpers ---

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
        return nil if url.blank?

        {sourceUri: {uri: url}}
      end

      # Resolve logo from the PassDefinition's owner group or its ancestors.
      # Uses the same ancestor-chain walk as LayoutHelper#closest_group_with_logo:
      # root -> self, first group with attached logo wins.
      # Falls back to Settings.application.logo if no group has a logo.
      def logo_image_uri
        group = pass.definition.owner
        logo_group = group.self_and_ancestors
          .includes(:logo_attachment)
          .reverse
          .find { |g| g.logo.attached? }

        url = if logo_group
          Rails.application.routes.url_helpers.rails_blob_url(logo_group.logo, only_path: false)
        else
          settings_logo_url
        end

        image_uri(url) if publicly_reachable_url?(url)
      end

      # Resolve the fallback application logo URL from the webpack manifest.
      # Settings.application.logo.image is a webpack-bundled asset (e.g. "logo.png"),
      # not a Sprockets asset. We look up the pack path from the manifest (checking
      # wagon-media first, mirroring WebpackHelper#wagon_image_pack_path), then build
      # an absolute URL using the app's default_url_options.
      def settings_logo_url
        logo_image = Settings.application.logo&.image
        return nil if logo_image.blank?

        manifest = Webpacker.instance.manifest
        pack_path = manifest.lookup("wagon-media/images/#{logo_image}") ||
          manifest.lookup("media/images/#{logo_image}")
        return nil unless pack_path

        absolute_url(pack_path)
      rescue Webpacker::Manifest::MissingEntryError
        nil
      end

      # Build an absolute URL from a relative path using the app's configured host.
      # Prefers routes.default_url_options, falls back to RAILS_HOST_NAME / RAILS_HOST_SSL
      # env vars (exposed in settings.yml as hostname/protocol).
      def absolute_url(path)
        opts = Rails.application.routes.default_url_options
        host = opts[:host]
        protocol = opts[:protocol]

        if host.blank?
          host = ENV["RAILS_HOST_NAME"].presence || "localhost:3000"
          protocol = %w[true yes 1].include?(ENV["RAILS_HOST_SSL"]) ? "https" : "http"
        end

        protocol ||= "http"
        port = opts[:port]
        base = "#{protocol}://#{host}"
        base += ":#{port}" if port
        "#{base}#{path}"
      end

      def publicly_reachable_url?(url)
        url.present? && url.start_with?("http") && !url.include?("localhost")
      end
    end
  end
end
