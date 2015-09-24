# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ActiveRecord
  module Type
    class Date < Value

      def date_string_to_long_year(string)
        return string unless string.is_a?(::String)
        return nil if string.empty?

        if string.strip =~ /\A(\d+)\.(\d+)\.(\d{2})\z/
          long_year = 1900 + $3.to_i
          long_year += 100 if long_year < 1940
          string = "#{$1}.#{$2}.#{long_year}"
        end

        string
      end

      private

      def fallback_string_to_date_with_long_year(string)
        fallback_string_to_date_without_long_year(date_string_to_long_year(string))
      end

      alias_method_chain :fallback_string_to_date, :long_year

    end
  end
end
