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

      PERMANENTLY_DELETED_REGEX = /\A(.*?)\swas\spermanently\sdeleted/

      attr_reader :data

      def initialize(data = {})
        @data = data.deep_symbolize_keys
      end

      def track(key, response)
        @data[key] = process(response) if response
      end

      def exception=(exception)
        @data[:exception] = [exception.class, exception.message].join(" - ")
      end

      def state # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
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

      def forgotten_emails
        operation_results(:subscribe_members).map do |op|
          op[:detail].to_s[PERMANENTLY_DELETED_REGEX, 1]
        end.compact_blank
      end

      private

      def exception?
        @data[:exception].present?
      end

      def operations
        @data.except(:exception).values
      end

      # wird nur aufgerufen, wenn operation ausgeführt wurde
      def process(response)
        total = response[:total_operations]
        failed = response[:errored_operations]
        finished = response[:finished_operations]
        operation_results = response[:operation_results]

        state = if total == failed || finished.zero?
          :failed
        elsif finished < total || failed.positive?
          :partial
        elsif total == finished
          :success
        end
        {state => [total, finished, failed, operation_results]}
      end

      # read operation_results from structure defined by #process
      def operation_results(key)
        Array(data[key].to_h.values.flatten(1).last)
      end
    end
  end
end
