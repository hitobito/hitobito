# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class TextMessageTransmitter

    def send(message)
      @message = message
    end

    private

    def settings
      @settings ||= fetch_settings
    end

    def fetch_settings
      recipient_source.group.settings(:text_message_provider)
    end

    def recipient_source
      @message.recipient_source
    end


  end
end
