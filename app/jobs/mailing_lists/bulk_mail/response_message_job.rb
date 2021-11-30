# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::ResponseMessageJob < BaseJob

  self.parameters = [:mail, :reason]

  def initialize(mail, reason)
    super()
  end

  def perform
  end

  def send_confirmation
    if participation.person.valid_email?
      Event::ParticipationMailer.confirmation(participation).deliver_now
    end
  end

end
