# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: passes
#
#  id                 :bigint           not null, primary key
#  state              :string           default("eligible"), not null
#  valid_from         :date             not null
#  valid_until        :date
#  verify_token       :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pass_definition_id :bigint           not null
#  person_id          :bigint           not null
#
# Indexes
#
#  idx_passes_unique             (person_id,pass_definition_id) UNIQUE
#  index_passes_on_verify_token  (verify_token) UNIQUE
#
class Pass < ActiveRecord::Base
  include I18nEnums

  STATES = %w[eligible ended revoked].freeze
  i18n_enum :state, STATES, scopes: true, queries: true

  has_secure_token :verify_token

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :pass_definition
  has_many :pass_installations, class_name: "Wallets::PassInstallation", dependent: :destroy

  ### VALIDATIONS

  validates_by_schema
  validates :person_id, uniqueness: {scope: :pass_definition_id}
  validates :state, inclusion: {in: ["eligible"]}, on: :create

  def definition = pass_definition

  def decorate
    PassDecorator.new(self)
  end
end
