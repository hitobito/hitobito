# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterMailer < ActionMailer::Base

  CONTENT_REGISTER_LOGIN = 'event_register_login'

  def register_login(recipient, group, event)
    content = CustomContent.get(CONTENT_REGISTER_LOGIN)
    url = event_url(recipient, group, event)
    values = {
      'recipient-name' => recipient.greeting_name,
      'event-name'     => event.to_s,
      'event-url'      => "<a href=\"#{url}\">#{url}</a>"
    }

    mail to: recipient.email, subject: content.subject do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def event_url(person, group, event)
    group_event_url(group, event, onetime_token: person.reset_password_token)
  end

end
