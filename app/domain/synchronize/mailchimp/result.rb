#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Synchronize
  module Mailchimp
    class Result
      STATE_BADGES = {
        unchanged: :success,
        success: :success,
        partial: :info,
        failed: :warning,
        fatal: :danger
      }.freeze

      attr_reader :data

      def initialize(data = {})
        @data = data.deep_symbolize_keys
      end

      def track(key, response)
        @data[key] = extract(response) if response
      end

      def exception=(exception)
        @data[:exception] = [exception.class, exception.message].join(" - ")
      end

      def state # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        if exception?
          :failed
        elsif operations.empty?
          :unchanged
        elsif operations.all? { |val| val.key?(:failed) }
          :failed
        elsif operations.any? { |val| val.key?(:partial) }
          :partial
        elsif operations.all? { |val| val.key?(:success) }
          :success
        end
      end

      def badge_info
        [state, STATE_BADGES[state]]
      end

      private

      def exception?
        @data[:exception].present?
      end

      def operations
        @data.except(:execption).values
      end

      # wird nur aufgerufen, wenn operation ausgeführt wurde
      def extract(response)
        total = response["total_operations"]
        failed = response["errored_operations"]
        finished = response["finished_operations"]
        response_body_url = response["response_body_url"]

        if total == failed || finished.zero?
          {failed: [total, response_body_url]}
        elsif finished < total || failed.positive?
          {partial: [total, failed, finished, response_body_url]}
        elsif total == finished
          {success: total}
        end
      end
    end
  end
end
