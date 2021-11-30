# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'
require 'mail'

class Imap::Mail

  attr_accessor :net_imap_mail, :mail_log

  delegate :subject, :sender, to: :envelope

  def self.build(net_imap_mail)
    entry = new
    entry.net_imap_mail = net_imap_mail
    entry
  end

  def uid
    @net_imap_mail.attr['UID']
  end

  def subject
    Mail::Encodings.value_decode(envelope.subject)
  end

  def date
    Time.zone.utc_to_local(DateTime.parse(envelope.date))
  end

  def sender_email
    envelope.sender[0].mailbox + '@' + envelope.sender[0].host
  end

  def email_to
    envelope.to[0].mailbox + '@' + envelope.to[0].host
  end

  def sender_name
    envelope.sender[0].name
  end

  def name_to
    envelope.to[0].name
  end

  def plain_text_body
    (mail.text_part || mail).body.decoded
  end

  def multipart_body
    return nil unless mail.multipart?

    mail.html_part.body.decoded
  end

  def hash
    Digest::MD5.new.hexdigest(raw_source)
  end

  def raw_source
    mail.raw_source
  end

  def original_to
    # TODO: get it from mail header
  end

  def mail
    @mail ||= Mail.read_from_string(@net_imap_mail.attr['RFC822'])
  end

  private

  def envelope
    @net_imap_mail.attr['ENVELOPE']
  end
end
