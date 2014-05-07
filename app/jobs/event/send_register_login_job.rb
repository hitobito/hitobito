# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::SendRegisterLoginJob < BaseJob

  self.parameters = [:recipient_id, :group_id, :event_id, :locale]

  def initialize(recipient, group, event)
    super()
    @recipient_id = recipient.id
    @group_id = group.id
    @event_id = event.id
  end

  def perform
    set_locale
    token = recipient.generate_reset_password_token!
    Event::RegisterMailer.register_login(recipient, group, event, token).deliver
  end

  def recipient
    @recipient ||= Person.find(@recipient_id)
  end

  def event
    @event ||= group.events.find(@event_id)
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
