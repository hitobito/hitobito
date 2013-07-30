# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonMailer < ActionMailer::Base

  CONTENT_LOGIN = 'send_login'

  def login(recipient, sender)
    content = CustomContent.get(CONTENT_LOGIN)
    values = {
      'recipient-name' => recipient.greeting_name,
      'sender-name'    => sender.to_s,
      'login-url'      => "<a href=\"#{login_url(recipient)}\">#{login_url(recipient)}</a>"
    }

    mail(to: recipient.email,
         return_path: return_path(sender),
         sender: return_path(sender),
         reply_to: sender.email,
         subject: content.subject) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  private

  def login_url(person)
    edit_person_password_url(person, reset_password_token: person.reset_password_token)
  end

  def return_path(sender)
    MailRelay::Lists.personal_return_path(MailRelay::Lists.app_sender_name, sender.email)
  end

end
