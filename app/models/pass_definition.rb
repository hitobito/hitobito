# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: pass_definitions
#
#  id               :bigint           not null, primary key
#  background_color :string           default("#ffffff"), not null
#  description      :text
#  name             :string
#  owner_type       :string           not null
#  template_key     :string           default("default"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :bigint           not null
#
# Indexes
#
#  index_pass_definitions_on_owner  (owner_type,owner_id)
#
class PassDefinition < ActiveRecord::Base
  include Globalized
  translates :name, :description

  ### ASSOCIATIONS

  # Logo-Attachments — per configured language, similar to Globalize translations.
  # Dynamically registered based on Settings.application.languages
  Globalized.languages.each do |lang|
    has_one_attached :"logo_icon_#{lang}"
    has_one_attached :"logo_banner_#{lang}"
    has_one_attached :"logo_secondary_#{lang}"
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

  validates :logo_icon, presence: true
  validates :logo_banner, presence: true

  Globalized.languages.each do |lang|
    validates :"logo_icon_#{lang}",
      content_type: %w[image/png image/jpeg],
      aspect_ratio: :square
    validates :"logo_banner_#{lang}",
      content_type: %w[image/png image/jpeg],
      aspect_ratio: :landscape
    validates :"logo_secondary_#{lang}",
      content_type: %w[image/png image/jpeg]
  end

  after_create :populate_passes
  after_update :handle_definition_change

  # Resolve the template bundle for this definition.
  # Returns a Passes::TemplateRegistry::Template with pdf_class, pass_view_partial,
  # wallet_data_provider.
  def template
    Passes::TemplateRegistry.fetch(template_key)
  end

  def logo_icon(locale = I18n.locale)
    find_localized_attachment(:logo_icon, locale)
  end

  def logo_banner(locale = I18n.locale)
    find_localized_attachment(:logo_banner, locale)
  end

  def logo_secondary(locale = I18n.locale)
    find_localized_attachment(:logo_secondary, locale)
  end

  private

  def populate_passes
    PassPopulateJob.new(id).enqueue!
  end

  def handle_definition_change
    Passes::DefinitionChangeHandler.new(self).handle_update
  end

  # Traverses the Globalize fallback chain and returns the first attachment
  # that exists and is attached for an app language — identical to Globalize's
  # Adapter#fetch: traverse chain, return nil when exhausted.
  #
  # Example: locale = :en, app languages = [:de, :fr, :it]
  #   → :en → logo_banner_en? respond_to? no → skip
  #   → :de → logo_banner_de? respond_to? yes, attached? → yes → return logo_banner_de
  #   → if nothing found: nil
  def find_localized_attachment(base_name, locale)
    Globalize.fallbacks(locale.to_sym)
      .lazy.map { |lang| try(:"#{base_name}_#{lang}") }
      .find { |attachment| attachment&.attached? }
  end
end
