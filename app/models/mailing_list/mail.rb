# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class MailingList::Mail

  attr_accessor :uid, :mailbox, :subject, :date, :sender_name, :sender_email, :body

  def initialize(imap_fetch_data: nil, mailbox: '')
    @mailbox = mailbox

    if imap_fetch_data.nil?
      default_init
    else
      unpack imap_fetch_data
    end
  end

  def preview
    if body.length > 43
      body[0..40] + '...'
    else
      body
    end
  end

  def date_formatted
    if date.today?
      I18n.l(date, format: :time)
    else
      I18n.l(date.to_date) + ' ' + I18n.l(date, format: :time)
    end
  end

  def subject_formatted
    if subject.length > 43
      subject[0..40] + '...'
    else
      subject
    end
  end

  private

  def default_init
    @uid = 0
    @subject = ''
    @date = ''
    @sender = ''
    @body = ''
  end

  def unpack(imap_fetch_data)
    @uid = imap_fetch_data['UID']

    envelope = imap_fetch_data['ENVELOPE']
    @subject = envelope.subject

    @date = Time.zone.utc_to_local(DateTime.parse(envelope.date))

    @sender_email = envelope.sender[0].mailbox + '@' + envelope.sender[0].host
    @sender_name = envelope.sender[0].name

    if imap_fetch_data['BODYSTRUCTURE'].media_type == 'TEXT'
      @body = imap_fetch_data['BODY[TEXT]']
    else
      mail = Mail.read_from_string imap_fetch_data['RFC822']
      @body = mail.text_part.body.to_s

    end
  end

end
