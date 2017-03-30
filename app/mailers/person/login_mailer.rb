# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::LoginMailer < ApplicationMailer

  CONTENT_LOGIN = 'send_login'.freeze

  def login(recipient, sender, token)
    @recipient = recipient
    @sender    = sender
    @token     = token

    values = values_for_placeholders(CONTENT_LOGIN)

    # This email contains sensitive information and thus
    # is only sent to the main email address.
    custom_content_mail(recipient.email, CONTENT_LOGIN, values, with_personal_sender(sender))
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_sender_name
    @sender.to_s
  end

  def placeholder_login_url
    link_to(login_url(@token))
  end

  def login_url(token)
    edit_person_password_url(reset_password_token: token)
  end

end
