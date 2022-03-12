# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::MessageJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:message_id]

  def initialize(format, user_id, message_id, options)
    super(format, user_id, options)
    @message_id = message_id
  end

  private

  def message
    @message ||= ::Message.find(@message_id)
  end

  def data
    case @format
    when :pdf
      message.exporter_class.new(message, {
        async_download_file: filename,
        stamped: true
      }).render
    end
  end

end
