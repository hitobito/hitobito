# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterMailer < ActionMailer::Base

  CONTENT_REGISTER_LOGIN = 'event_register_login'

  def register_login(recipient, group, event, token)
    content = CustomContent.get(CONTENT_REGISTER_LOGIN)
    url = event_url(group, event, token)
    values = {
      'recipient-name' => recipient.greeting_name,
      'event-name'     => event.to_s,
      'event-url'      => "<a href=\"#{url}\">#{url}</a>"
    }

    # This email contains sensitive information and thus
    # is only sent to the main email address.
    mail(to: recipient.email, subject: content.subject) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  private

  def event_url(group, event, token)
    group_event_url(group, event, onetime_token: token)
  end

end
