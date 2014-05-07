# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SendLoginJob < BaseJob

  self.parameters = [:recipient_id, :sender_id, :locale]

  def initialize(recipient, sender)
    super()
    @recipient_id = recipient.id
    @sender_id = sender.id
  end

  def perform
    set_locale
    token = recipient.generate_reset_password_token!
    PersonMailer.login(recipient, sender, token).deliver
  end

  def sender
    @sender ||= Person.find(@sender_id)
  end

  def recipient
    @recipient ||= Person.find(@recipient_id)
  end
end
