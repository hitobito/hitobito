# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class DateRange < Base
    self.permitted_args = [:since, :until]

    def apply(scope)
      if since_date && until_date
        scope.between(since_date, until_date)
      elsif since_date
        scope.after_or_on(since_date)
      elsif until_date
        scope.before_or_on(until_date)
      else
        scope
      end
    end

    def blank?
      !since_date && !until_date
    end

    private

    def since_date
      return @since if defined?(@since)

      @since = date_or_default(args[:since])
    end

    def until_date
      return @until if defined?(@until)

      @until = date_or_default(args[:until])
    end

    def date_or_default(date)
      return Date.parse(date) if date.is_a?(String)

      date.to_date
    rescue
      nil
    end
  end
end
