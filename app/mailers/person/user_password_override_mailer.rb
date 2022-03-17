# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::UserPasswordOverrideMailer < ApplicationMailer

  CONTENT_USER_PASSWORD_OVERRIDE = 'content_user_password_override'.freeze

  delegate :body, :person, :requester, to: :password_override

  def send_mail(recipient, taker_name)
    @recipient = recipient
    @taker_name = taker_name

    compose(recipient, CONTENT_USER_PASSWORD_OVERRIDE)
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_taker_name
    @taker_name
  end
end
