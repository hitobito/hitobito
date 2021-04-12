# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class Imap::Mail

  attr_accessor :imap_mail

  delegate :subject, :sender, to: :envelope

  def self.build(imap_mail)
    entry = new
    entry.imap_mail = imap_mail
    entry
  end

  def uid
    @imap_mail.attr['UID']
  end

  def date
    Time.zone.utc_to_local(DateTime.parse(envelope.date))
  end

  def sender_email
    envelope.sender[0].mailbox + '@' + envelope.sender[0].host
  end

  def sender_name
    envelope.sender[0].name
  end

  def body
    if @imap_mail.attr['BODYSTRUCTURE'].media_type == 'TEXT'
      @imap_mail.attr['BODY[TEXT]']
    else
      mail = Mail.read_from_string @imap_mail.attr['RFC822']
      mail.text_part.body.to_s
    end
  end

  private

  def envelope
    @imap_mail.attr['ENVELOPE']
  end

end
