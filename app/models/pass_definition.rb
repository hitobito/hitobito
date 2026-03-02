# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class PassDefinition < ActiveRecord::Base
  include Globalized

  belongs_to :owner, polymorphic: true # Group (Event in future phase)
  has_many :pass_grants, dependent: :destroy
  has_many :passes, dependent: :destroy
  has_many :pass_installations, class_name: "Wallets::PassInstallation",
    through: :passes

  translates :name, :description

  validates :name, presence: true
  validates :template_key, presence: true,
    inclusion: {in: ->(_) { Passes::TemplateRegistry.available_keys }}
  validates :background_color, presence: true,
    format: {with: /\A#[0-9a-fA-F]{6}\z/, message: :invalid_hex_color}

  after_create :populate_passes
  after_update :handle_definition_change

  # Resolve the template bundle for this definition.
  # Returns a Passes::TemplateRegistry::Template with pdf_class, pass_view_partial,
  # wallet_data_provider.
  def template
    Passes::TemplateRegistry.fetch(template_key)
  end

  private

  def populate_passes
    PassPopulateJob.new(id).enqueue!
  end

  def handle_definition_change
    Passes::DefinitionChangeHandler.new(self).handle_update
  end
end
