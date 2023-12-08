# frozen_string_literal: true

# == Schema Information
#
# Table name: message_recipients
#
#  id           :bigint           not null, primary key
#  address      :text(65535)
#  email        :string(255)
#  error        :text(65535)
#  failed_at    :datetime
#  phone_number :string(255)
#  salutation   :string(255)      default("")
#  state        :string(255)
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
#  index_message_recipients_on_person_message_phone_number  (person_id,message_id,phone_number) UNIQUE # rubocop:disable Layout/LineLength
#

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
