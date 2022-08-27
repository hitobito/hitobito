# frozen_string_literal: true

#  Copyright (c) 2012-2022, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessageRecipient < ActiveRecord::Base
  include I18nEnums
  validates_by_schema

  STATES = %w(pending sending sent failed).freeze
  i18n_enum :state, STATES
  validates :state, inclusion: { in: STATES }, allow_nil: true

  belongs_to :message
  belongs_to :person
  has_one :mailing_list, through: :message, dependent: :restrict_with_error

  scope :list, -> { order(:dispatched_at) }
end
