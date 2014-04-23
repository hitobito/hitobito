# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonMailer < ActionMailer::Base

  CONTENT_LOGIN = 'send_login'

  def login(recipient, sender, token)
    content = CustomContent.get(CONTENT_LOGIN)

    # This email contains sensitive information and thus
    # is only sent to the main email address.
    mail(to: recipient.email,
         return_path: return_path(sender),
         sender: return_path(sender),
         reply_to: sender.email,
         subject: content.subject) do |format|
      format.html { render text: content_body(content, recipient, sender, token) }
    end
  end

  private

  def content_body(content, recipient, sender, token)
    url = login_url(recipient, token)
    content.body_with_values(
      'recipient-name' => recipient.greeting_name,
      'sender-name'    => sender.to_s,
      'login-url'      => "<a href=\"#{url}\">#{url}</a>")
  end

  def login_url(person, token)
    edit_person_password_url(reset_password_token: token)
  end

  def return_path(sender)
    MailRelay::Lists.personal_return_path(MailRelay::Lists.app_sender_name, sender.email)
  end

end
