module Synchronize
  module Mailchimp
    class ResultType < ActiveRecord::Type::Value

      # to db
      def serialize(result)
        result ? result.data.to_json : nil
      end

      # from user or db
      def cast(value)
        case value
        when String then Synchronize::Mailchimp::Result.new(JSON.parse(value))
        when Hash then Synchronize::Mailchimp::Result.new(value)
        when Synchronize::Mailchimp::Result then value
        else Synchronize::Mailchimp::Result.new
        end
      end

    end
  end
end
