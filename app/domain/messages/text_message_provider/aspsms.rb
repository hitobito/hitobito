# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# https://json.aspsms.com/

require "rest-client"

module Messages
  module TextMessageProvider
    class Aspsms < Base

      SEND_URL = "https://json.aspsms.com/SendSimpleTextSMS"
      DELIVERY_REPORTS_URL = "https://json.aspsms.com/InquireDeliveryNotifications"
      MAX_CHARS = 160

      STATUS = {
        "0" => STATUS_OK,
        "1" => STATUS_OK,
        "3" => STATUS_AUTH_ERROR
      }.freeze

      def send(text:, recipients: [])
        params = default_params
        params[:Originator] = @config.originator
        params[:MessageText] = text[0..MAX_CHARS - 1]
        params[:Recipients] = recipients[0..MAX_RECIPIENTS - 1]
        response = RestClient.post(SEND_URL, params.to_json)
        result(response)
      end

      def delivery_reports(recipient_ids: [])
        params = default_params
        params[:TransactionReferenceNumbers] = recipient_ids.join(";")
        response = RestClient.post(DELIVERY_REPORTS_URL, params.to_json)
        result(response) do |r, data|
          r[:delivery_reports] = collect_delivery_notifications(data)
        end
      end

      private

      def collect_delivery_notifications(response_data)
        notifications = response_data["DeliveryNotifications"]
        return if notifications.nil?

        notifications.each_with_object({}) do |n, h|
          id = n["TransactionReferenceNumber"]
          h[id] = {
            status: delivery_status(n["DeliveryStatus"]),
            status_message: n["DeliveryStatusDescription"]
          }
        end
      end

      def result(response)
        data = JSON.parse(response.body)
        r = { status: status(data), message: data["StatusInfo"] }
        yield(r, data) if block_given?
        r
      end

      def status(response_json)
        status_code = response_json["StatusCode"]
        STATUS[status_code] || STATUS_ERROR
      end

      def delivery_status(status_value)
        status_value.eql?("0") ? :ok : :error
      end

      def default_params
        { UserName: @config.username,
          Password: @config.password }
      end

    end
  end
end
