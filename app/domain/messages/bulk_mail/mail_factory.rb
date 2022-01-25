# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
    module BulkMail
      class MailFactory
        # @param [Message] message
        def initialize(message)
          @message = message
        end

        # @param [[String]] receivers Receiver E-Mails
        # @return [Mail::Message]
        def to(receivers)
          raise "Implement me"
        end
      end
    end
  end
