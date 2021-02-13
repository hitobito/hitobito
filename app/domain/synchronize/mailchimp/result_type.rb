#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
