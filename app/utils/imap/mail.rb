# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'
require 'mail'

class Imap::Mail

  attr_accessor :net_imap_mail

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
    Time.zone.utc_to_local(DateTime.parse(envelope.date.presence || DateTime.now.to_s))
  end

  def sender_email
    envelope.sender[0].mailbox + '@' + envelope.sender[0].host
  end

  def sender_name
    envelope.sender[0].name
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
    mail.header['X-Original-To'].value
  end

  def list_bounce?
    bounce_return_path? &&
      bounce_hitobito_message_uid.present?
  end

  def bounce_hitobito_message_uid
    mail.body.raw_source[/X-Hitobito-Message-UID: ([a-z0-9]*)/,1]
  end

  def mail
    @mail ||= Mail.read_from_string(@net_imap_mail.attr['RFC822'])
  end

  private

  def envelope
    @net_imap_mail.attr['ENVELOPE']
  end

  def bounce_return_path?
    return_path.eql?('') ||
      return_path.include?('MAILER-DAEMON')
  end

  def return_path
    mail.header['Return-Path'].value
  end

end
