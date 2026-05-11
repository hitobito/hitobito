# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class PassDefinition < ActiveRecord::Base
  include Globalized
  translates :name, :description

  ### ASSOCIATIONS
  #
  # Logo-Attachments — pro konfigurierter Sprache, analog zu Globalize-Übersetzungen.
  # Dynamisch registriert basierend auf Settings.application.languages.
  Globalized.languages.each do |lang|
    has_one_attached :"logo_icon_#{lang}"
    has_one_attached :"logo_banner_#{lang}"

    # Automatische Varianten-Generierung beim Attachen
    after_save :"process_logo_icon_variants_#{lang}", if: :"logo_icon_#{lang}_attached?"
    after_save :"process_logo_banner_variants_#{lang}", if: :"logo_banner_#{lang}_attached?"
  end

  belongs_to :owner, polymorphic: true # Group (Event in future phase)
  has_many :pass_grants, dependent: :destroy
  has_many :passes, dependent: :destroy
  has_many :pass_installations, class_name: "Wallets::PassInstallation",
    through: :passes

  ### VALIDATIONS

  validates_by_schema
  validates :name, presence: true

  # template_key: Identifies the template bundle (PDF renderer, wallet view, data provider).
  validates :template_key, presence: true,
    inclusion: {in: ->(_) { Passes::TemplateRegistry.available_keys }}

  # background_color: Hex color (#rrggbb) for pass background in wallet and PDF rendering.
  validates :background_color, presence: true,
    format: {with: /\A#[0-9a-fA-F]{6}\z/, message: :invalid_hex_color}

  # Logo-Attachments validation
  Globalized.languages.each do |lang|
    validates :"logo_icon_#{lang}",
              content_type: %w[image/png image/jpeg],
              dimension: {min: {width: 512, height: 512}},
              aspect_ratio: :square
    validates :"logo_banner_#{lang}",
              content_type: %w[image/png image/jpeg],
              dimension: {min: {width: 1032, height: 336}}
  end

  validate :logo_banner_aspect_ratio
  validate :logo_icon_present
  validate :logo_banner_present

  after_create :populate_passes
  after_update :handle_definition_change

  # Resolve the template bundle for this definition.
  # Returns a Passes::TemplateRegistry::Template with pdf_class, pass_view_partial,
  # wallet_data_provider.
  def template
    Passes::TemplateRegistry.fetch(template_key)
  end

  # Locale-aware Accessor für das quadratische Icon — analog zu Globalize-Attributen.
  # Gibt das Attachment für die angeforderte Sprache zurück (mit Fallback-Kette).
  # Beispiel: definition.logo_icon        → Attachment für I18n.locale
  #           definition.logo_icon(:fr)   → Attachment für :fr (oder Fallback)
  def logo_icon(locale = I18n.locale)
    find_localized_attachment(:logo_icon, locale)
  end

  # Locale-aware Accessor für das Landscape-Banner — analog zu Globalize-Attributen.
  def logo_banner(locale = I18n.locale)
    find_localized_attachment(:logo_banner, locale)
  end

  private

  def populate_passes
    PassPopulateJob.new(id).enqueue!
  end

  def handle_definition_change
    Passes::DefinitionChangeHandler.new(self).handle_update
  end

  # Durchläuft die Globalize-Fallback-Kette und gibt das erste Attachment zurück,
  # das für eine App-Sprache existiert und attached ist — identisch mit Globalize's
  # Adapter#fetch: Kette traversieren, nil zurückgeben wenn erschöpft.
  #
  # Beispiel: locale = :en, App-Sprachen = [:de, :fr, :it]
  #   → :en → logo_banner_en? respond_to? nein → skip
  #   → :de → logo_banner_de? respond_to? ja, attached? → ja → return logo_banner_de
  #   → falls nichts gefunden: nil
  def find_localized_attachment(base_name, locale)
    Globalize.fallbacks(locale.to_sym).each do |lang|
      next unless respond_to?(:"#{base_name}_#{lang}")
      attachment = public_send(:"#{base_name}_#{lang}")
      return attachment if attachment.attached?
    end
    nil
  end

  def logo_icon_present
    return if Globalized.languages.any? { |lang| public_send(:"logo_icon_#{lang}").attached? }
    errors.add(:base, :at_least_one_logo_icon_required)
  end

  def logo_banner_present
    return if Globalized.languages.any? { |lang| public_send(:"logo_banner_#{lang}").attached? }
    errors.add(:base, :at_least_one_logo_banner_required)
  end

  def logo_banner_aspect_ratio
    Globalized.languages.each do |lang|
      next unless attachment_changes.key?("logo_banner_#{lang}")
      attachment = public_send(:"logo_banner_#{lang}")
      next unless attachment.attached?
      blob = attachment.blob
      blob.analyze unless blob.analyzed?
      meta = blob.metadata
      ratio = meta[:width].to_f / meta[:height]
      unless ratio.between?(2.5, 4.0)
        errors.add(:"logo_banner_#{lang}", :aspect_ratio_not_landscape_banner)
      end
    end
  end

  # Dynamische Methoden für Varianten-Generierung
  Globalized.languages.each do |lang|
    define_method :"process_logo_icon_variants_#{lang}" do
      attachment = public_send(:"logo_icon_#{lang}")
      # Vorab-Generieren der benötigten Varianten für Apple Wallet
      attachment.variant(resize_to_fill: [29, 29], format: :png).processed
      attachment.variant(resize_to_fill: [58, 58], format: :png).processed
      attachment.variant(resize_to_fill: [90, 90], format: :png).processed
      attachment.variant(resize_to_fill: [180, 180], format: :png).processed
      # Google Wallet: 800×800
      attachment.variant(resize_to_fill: [800, 800], format: :png).processed
    end

    define_method :"process_logo_banner_variants_#{lang}" do
      attachment = public_send(:"logo_banner_#{lang}")
      # Vorab-Generieren der benötigten Varianten für Apple Wallet
      attachment.variant(resize_to_fit: [160, 50], format: :png).processed
      attachment.variant(resize_to_fit: [320, 100], format: :png).processed
      # Google Wallet heroImage: ~1032×336
      attachment.variant(resize_to_fit: [1032, 336], format: :png).processed
    end

    define_method :"logo_icon_#{lang}_attached?" do
      attachment_changes.key?("logo_icon_#{lang}")
    end

    define_method :"logo_banner_#{lang}_attached?" do
      attachment_changes.key?("logo_banner_#{lang}")
    end
  end
end
