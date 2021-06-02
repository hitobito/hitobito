# frozen_string_literal: true

# == Schema Information
#
# Table name: message_recipients
#
#  id           :bigint           not null, primary key
#  address      :string(255)
#  email        :string(255)
#  error        :text(65535)
#  failed_at    :datetime
#  phone_number :string(255)
#  state        :string(255)
#  created_at   :datetime
#  invoice_id   :bigint
#  message_id   :bigint           not null
#  person_id    :bigint           not null
#
# Indexes
#
#  index_message_recipients_on_invoice_id  (invoice_id)
#  index_message_recipients_on_message_id  (message_id)
#  index_message_recipients_on_person_id   (person_id)
#


#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
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
