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
      MAX_CHARS = 160
      MAX_RECIPIENTS_BLOCK = 1000

      STATUS = {
        '1' => STATUS_OK,
        '3' => STATUS_AUTH_ERROR
      }.freeze

      def send(text:, recipients: [])
        params = config_params
        params[:MessageText] = text[0..MAX_CHARS - 1]
        params[:Recipients] = recipients[0..MAX_RECIPIENTS_BLOCK - 1]
        r = RestClient.post(SEND_URL, params.to_json)
        result(r)
      end

      private

      def result(response)
        r = JSON.parse(response.body)
        { status: status(r), message: r['StatusInfo'] }
      end

      def status(response_json)
        status_code = response_json['StatusCode']
        STATUS[status_code] || STATUS_ERROR
      end

      def config_params
        { UserName: @config[:username],
          Password: @config[:password],
          Originator: @config[:originator] }
      end

    end
  end
end
