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

      def subscribed=(response)
        @data[:subscribed] = extract(response) if response
      end

      def deleted=(response)
        @data[:deleted] = extract(response) if response
      end

      def tags=(response)
        @data[:tags] = extract(response) if response
      end

      def merge_fields=(response)
        @data[:merge_fields] = extract(response) if response
      end

      def updates=(response)
        @data[:updates] = extract(response) if response
      end


      def exception=(exception)
        @data[:exception] = [exception.class, exception.message].join(' - ')
      end

      def state
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
        @data.slice(:subscribed, :deleted, :tags, :merge_fields).values
      end

      # wird nur aufgerufen, wenn operation ausgeführt wurde
      def extract(response)
        total = response['total_operations']
        failed = response['errored_operations']
        finished = response['finished_operations']
        response_body_url = response['response_body_url']

        if total == failed || finished.zero?
          { failed: [total, response_body_url] }
        elsif finished < total || failed.positive?
          { partial: [total, failed, finished, response_body_url] }
        elsif total == finished
          { success: total }
        end
      end
    end
  end
end
