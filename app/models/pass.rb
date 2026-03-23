# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Pass < ActiveRecord::Base
  include I18nEnums

  belongs_to :person
  belongs_to :pass_definition
  has_many :pass_installations, class_name: "Wallets::PassInstallation", dependent: :destroy

  STATES = %w[eligible ended revoked].freeze
  i18n_enum :state, STATES, scopes: true, queries: true

  validates :person_id, uniqueness: {scope: :pass_definition_id}
  validates :state, inclusion: {in: ["eligible"]}, on: :create

  def decorate
    PassDecorator.new(self)
  end
end
