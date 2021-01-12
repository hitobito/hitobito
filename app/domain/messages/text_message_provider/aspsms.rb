# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# https://json.aspsms.com/

module Messages
  module TextMessageProvider
    class Aspsms < Base

      SEND_URL = 'https://json.aspsms.com/SendSimpleTextSMS'

      def send(text:, recipients: [])
        params = config_params
        params[:MessageText] = text
        params[:Recipients] = recipients
        r = RestClient.post(SEND_URL, params.to_json)
        JSON.parse(r.body)
      end

      private

      def config_params
        { UserName: @config[:username],
          Password: @config[:password],
          Originator: @config[:originator] }
      end

    end
  end
end
