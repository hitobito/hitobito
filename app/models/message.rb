# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  failed_count       :integer          default(0)
#  heading            :boolean          default(FALSE)
#  invoice_attributes :text(65535)
#  recipient_count    :integer          default(0)
#  salutation         :string(255)
#  sent_at            :datetime
#  state              :string(255)      default("draft")
#  subject            :string(256)
#  success_count      :integer          default(0)
#  text               :text(65535)
#  type               :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  invoice_list_id    :bigint
#  mailing_list_id    :bigint
#  sender_id          :bigint
#
# Indexes
#
#  index_messages_on_invoice_list_id  (invoice_list_id)
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#

#  id              :bigint           not null, primary key
#  failed_count    :integer          default(0)
#  recipient_count :integer          default(0)
#  invoice_attributes :text(16777215)
#  sent_at         :datetime
#  state           :string(255)      default("draft")
#  subject         :string(1024)
#  success_count   :integer          default(0)
#  type            :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mailing_list_id :bigint
#  sender_id       :bigint
#  invoice_list_id :bigint
#  heading         :boolean          default("false")
#
# Indexes
#
#  index_messages_on_invoice_list_id  (invoice_list_id)
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Message < ActiveRecord::Base
  include I18nEnums

  validates_by_schema except: :text
  belongs_to :invoice_list
  belongs_to :mailing_list
  belongs_to :sender, class_name: 'Person'
  has_many :message_recipients, dependent: :restrict_with_error
  has_one :group, through: :mailing_list

  # bulk mail only
  has_one :mail_log, foreign_key: :message_id, dependent: :nullify, inverse_of: :message

  has_many :assignments, as: :attachment, dependent: :destroy

  STATES = %w(draft pending processing finished failed).freeze
  i18n_enum :state, STATES, scopes: true, queries: true
  validates :state, inclusion: { in: STATES }

  class_attribute :duplicatable_attrs
  self.duplicatable_attrs = %w(subject type mailing_list_id)

  scope :list, -> { order(:created_at) }

  attr_readonly :type

  class_attribute :icon
  self.icon = :envelope

  class << self
    def all_types
      [Message::TextMessage,
       Message::Letter,
       Message::LetterWithInvoice,
       Message::BulkMail]
    end

    def find_message_type!(sti_name)
      type = all_types.detect { |t| t.sti_name == sti_name }
      raise ActiveRecord::RecordNotFound, "No event type '#{sti_name}' found" if type.nil?

      type
    end
  end

  def to_s
    subject ? "#{type.constantize.model_name.human}: #{subject.truncate(20)}" : super
  end

  def dispatch!
    update!(
      recipient_count: mailing_list.people.size,
      state: :pending
    )
    Messages::DispatchJob.new(self).enqueue!
  end

  def letter?
    is_a?(Message::Letter)
  end

  def invoice?
    is_a?(Message::LetterWithInvoice)
  end

  def text_message?
    is_a?(Message::TextMessage)
  end

  def bulk_mail_message?
    is_a?(Message::BulkMail)
  end

  def dispatched?
    state != 'draft'
  end

  def dispatcher_class
    "Messages::#{type.demodulize}Dispatch".constantize
  end

  def path_args
    [group, mailing_list, self]
  end

  def exporter_class
    "Export::Pdf::Messages::#{type.demodulize}".constantize
  end

  def total_recipient_count
    @total_recipient_count ||= mailing_list.people_count
  end

  def valid_recipient_count
    raise 'implement in subclass'
  end

  def invalid_recipient_count
    total_recipient_count - valid_recipient_count
  end

end
