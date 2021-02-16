# frozen_string_literal: true

#  Copyright (c) 2018-2020, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: mail_logs
#
#  id                :integer          not null, primary key
#  mail_from         :string(255)
#  mail_hash         :string(255)
#  mailing_list_name :string(255)
#  status            :integer          default("retreived")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_id        :bigint
#
# Indexes
#
#  index_mail_logs_on_mail_hash   (mail_hash)
#  index_mail_logs_on_message_id  (message_id)
#

class MailLog < ActiveRecord::Base

  belongs_to :message

  STATES = [:retreived, :bulk_delivering, :completed, :sender_rejected, :unkown_recipient].freeze
  enum status: STATES

  BULK_MESSAGE_STATUS = { bulk_delivering: :processing,
                          retreived: :pending,
                          completed: :finished,
                          sender_rejected: :failed,
                          unkown_recipient: :failed }.freeze

  validates_by_schema

  validates :mail_hash, uniqueness: { case_sensitive: false }

  scope :list, -> { order(updated_at: :desc) }

  before_update :update_message_state, if: :status_changed?

  class << self
    def build(mail)
      mail_log = new
      mail_log.mail = mail
      mail_log
    end
  end

  def update_message_state
    message.state = BULK_MESSAGE_STATUS[status.to_sym]
    message.sent_at = updated_at
    message.save!
  end

  def exists?
    return false unless mail_hash

    self.class.exists?(mail_hash: mail_hash)
  end

  def mail=(mail)
    self.mail_from = Array(mail.from).first
    self.mail_hash = md5_hash(mail)
    self.message = Message::BulkMail.new(subject: mail.subject, state: :pending)
  end

  private

  def md5_hash(mail)
    Digest::MD5.new.hexdigest(mail.raw_source)
  end
end
