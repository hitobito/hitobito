# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationMailer < ActionMailer::Base

  HEADERS_TO_SANITIZE = [:to, :cc, :bcc, :from, :sender, :return_path, :reply_to]

  def mail(headers = {}, &block)
    HEADERS_TO_SANITIZE.each do |h|
      if headers.key?(h)
        headers[h] = IdnSanitizer.sanitize(headers[h])
      end
    end
    super(headers, &block)
  end

  private
  
  # use list return path functionality to send a 'no-reply' email with the sender's email
  # as reply-to address
  def return_path(sender)
    MailRelay::Lists.personal_return_path(MailRelay::Lists.app_sender_name, sender.email)
  end

end
