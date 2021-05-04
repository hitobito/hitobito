# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::MessageJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:message_id]

  def initialize(user_id, message_id, filename)
    super(:pdf, user_id, filename: filename)
    @message_id = message_id
  end

  private

  def message
    @message ||= Message.find(@message_id)
  end

  def recipients
    @recipients ||= message.mailing_list.people(Person.with_address)
  end

  def data
    message.exporter_class.new(message, recipients, {
      stamped: true
    }).render
  end


end
