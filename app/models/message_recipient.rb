# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Layout/LineLength
# rubocop:enable Layout/LineLength
class MessageRecipient < ActiveRecord::Base
  STATES = %w[pending sending sent failed blocked].freeze

  include I18nEnums

  i18n_enum :state, STATES

  belongs_to :message
  belongs_to :person
  has_one :mailing_list, through: :message, dependent: :restrict_with_error

  validates_by_schema
  validates :state, inclusion: {in: STATES}, allow_nil: true

  normalizes :email, with: ->(attribute) { attribute.downcase }

  scope :list, -> { order(:dispatched_at) }
end
