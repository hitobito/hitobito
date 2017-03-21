# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::LoginMailer < ApplicationMailer

  CONTENT_LOGIN = 'send_login'

  def login(recipient, sender, token)
    @recipient = recipient
    @sender    = sender
    @token     = token

    values = placeholder_values(CONTENT_LOGIN)

    # This email contains sensitive information and thus
    # is only sent to the main email address.
    custom_content_mail(recipient.email, CONTENT_LOGIN, values, with_personal_sender(sender))
  end

  private

  define_method("#{CONTENT_LOGIN}_values") do
    { 'recipient-name' => @recipient.greeting_name,
      'sender-name'    => @sender.to_s,
      'login-url'      => link_to(login_url(@token)) }
  end

  def login_url(token)
    edit_person_password_url(reset_password_token: token)
  end

end
