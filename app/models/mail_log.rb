# encoding: utf-8

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
#  mail_subject      :string(255)
#  mail_hash         :string(255)
#  status            :integer          default(0)
#  mailing_list_name :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class MailLog < ActiveRecord::Base

  delegate :mailing_list, to: :message

  enum status: [:retreived, :bulk_delivering, :completed, :sender_rejected, :unkown_recipient]

  belongs_to :message

  validates_by_schema

  validates :mail_hash, uniqueness: { case_sensitive: false }

  scope :list, -> { order(updated_at: :desc) }

  ### CLASS METHODS

  class << self
    def build(mail)
      mail_log = new
      mail_log.mail = mail
      mail_log
    end

    def in_year(year)
      year = Time.zone.today.year if year.to_i <= 0
      start_at = Time.zone.parse "#{year}-01-01"
      finish_at = start_at + 1.year
      where(updated_at: [start_at...finish_at])
    end
  end

  def exists?
    return false unless mail_hash

    self.class.exists?(mail_hash: mail_hash)
  end

  def mail=(mail)
    self.mail_subject = mail.subject
    self.mail_from = Array(mail.from).first
    self.mail_hash = md5_hash(mail)
  end

  private

  def md5_hash(mail)
    Digest::MD5.new.hexdigest(mail.raw_source)
  end

end
