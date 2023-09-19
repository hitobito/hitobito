# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  module TextMessageProvider
    class Base

      STATUS_OK = :ok
      STATUS_ERROR = :error
      STATUS_AUTH_ERROR = :auth_error

      MAX_RECIPIENTS = 1000

      def self.init(config:)
        case config.provider
        when 'aspsms'
          Aspsms.new(config: config)
        else
          raise 'unkown text message provider in config'
        end
      end

      def initialize(config:)
        @config = config
      end

      def send(_text:, _recipients:)
        raise 'implement in subclass'
      end

      def delivery_reports(_recipient_ids:)
        raise 'implement in subclass'
      end
    end
  end
end
