# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterMailer < ApplicationMailer

  CONTENT_REGISTER_LOGIN = 'event_register_login'.freeze

  def register_login(recipient, group, event, token)
    @recipient = recipient
    @group     = group
    @event     = event
    @token     = token
    # This email contains sensitive information and thus
    # is only sent to the main email address.
    custom_content_mail(
      recipient.email,
      CONTENT_REGISTER_LOGIN,
      values_for_placeholders(CONTENT_REGISTER_LOGIN)
    )
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_event_name
    @event.to_s
  end

  def placeholder_event_url
    link_to(event_url(@group, @event, @token))
  end

  def event_url(group, event, token)
    group_event_url(group, event, onetime_token: token)
  end

end
