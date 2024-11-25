# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Layout/LineLength

# == Schema Information
#
# Table name: message_recipients
#
#  id           :bigint           not null, primary key
#  address      :text
#  email        :string
#  error        :text
#  failed_at    :datetime
#  phone_number :string
#  salutation   :string           default("")
#  state        :string
#  created_at   :datetime
#  invoice_id   :bigint
#  message_id   :bigint           not null
#  person_id    :bigint
#
# Indexes
#
#  index_message_recipients_on_invoice_id                   (invoice_id)
#  index_message_recipients_on_message_id                   (message_id)
#  index_message_recipients_on_person_id                    (person_id)
#  index_message_recipients_on_person_message_address       (person_id,message_id,address) UNIQUE
#  index_message_recipients_on_person_message_email         (person_id,message_id,email) UNIQUE
#  index_message_recipients_on_person_message_phone_number  (person_id,message_id,phone_number) UNIQUE
#

# rubocop:enable Layout/LineLength
class MessageRecipient < ActiveRecord::Base
  include I18nEnums
  validates_by_schema

  STATES = %w[pending sending sent failed].freeze
  i18n_enum :state, STATES
  validates :state, inclusion: {in: STATES}, allow_nil: true

  belongs_to :message
  belongs_to :person
  has_one :mailing_list, through: :message, dependent: :restrict_with_error

  scope :list, -> { order(:dispatched_at) }
end
