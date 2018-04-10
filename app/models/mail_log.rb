# encoding: utf-8

#  Copyright (c) 2018, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailLog < ActiveRecord::Base

  enum status: [ :retreived, :bulk_delivering, :completed, :sender_rejected, :unkown_recipient ]

  belongs_to :mailing_list

  validates_by_schema

  validates :mail_hash, uniqueness: true

  def self.build(mail)
    mail_log = new
    mail_log.mail = mail
    mail_log
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

  def mail_subject=(value)
    value = I18n.transliterate(value, '?') if value.present?
    super(value)
  end

  private

  def md5_hash(mail)
    Digest::MD5.new.hexdigest(mail.raw_source)
  end

end
