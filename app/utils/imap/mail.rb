# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class Imap::Mail

  def initialize(imap_mail)
    @imap_mail = imap_mail
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

  def uid
    @imap_mail.attr['UID']
  end

  def subject
    envelope.subject
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
