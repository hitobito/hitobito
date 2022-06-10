# frozen_string_literal: true

#  Copyright (c) 2017-2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Mail < AppStatus

  CATCH_ALL_INBOX_OVERDUE = 'catch-all mailbox contains overdue mails. ' \
                            'please make sure delayed job worker is running ' \
                            'and no e-mail is blocking the queue/job.'
  CATCH_ALL_INBOX_OK = 'ok'

  CATCH_ALL_INBOX_OVERDUE_TIME = 42.minutes

  def initialize
    @catch_all_inbox = catch_all_inbox
  end

  def details
    { catch_all_inbox: @catch_all_inbox }
  end

  def code
    @catch_all_inbox.eql?(CATCH_ALL_INBOX_OK) ? :ok : :service_unavailable
  end

  private

  def catch_all_inbox
    update_seen_mails
    overdue = seen_mails.any? do |m|
      m.first_seen < DateTime.now - CATCH_ALL_INBOX_OVERDUE_TIME
    end

    overdue ? CATCH_ALL_INBOX_OVERDUE : CATCH_ALL_INBOX_OK
  end

  def update_seen_mails
    reject_processed_mails
    add_new_mails
    Rails.cache.write(:app_status, seen_mails: seen_mails)
  end

  def add_new_mails
    new_mails = current_mails.select do |m|
      seen_mails.exclude?(m)
    end
    @seen_mails += new_mails
  end

  def reject_processed_mails
    seen_mails.reject! do |m|
      current_mails.exclude?(m)
    end
  end

  def current_mails
    @current_mails ||= fetch_mails.collect { |m| SeenMail.build(m) }
  end

  def fetch_mails
    ::Mail.all
  end

  def seen_mails
    @seen_mails ||= app_status_cache.try(:[], :seen_mails) || []
  end

  def app_status_cache
    Rails.cache.read(:app_status)
  end

  class SeenMail
    attr_accessor :mail_hash, :first_seen

    def self.build(mail)
      seen_mail = SeenMail.new
      seen_mail.mail_hash = Digest::MD5.new.hexdigest(mail.raw_source)
      seen_mail.first_seen = DateTime.now
      seen_mail
    end

    def ==(other)
      mail_hash == other.mail_hash
    end

  end

end
