# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class DateRange < Base
    self.permitted_args = [:since, :until]

    def apply(scope)
      if start_date && end_date
        scope.joins(:dates).between(start_date, end_date)
      elsif start_date
        scope.joins(:dates).since(start_date)
      elsif end_date
        scope.joins(:dates).before_or_on(end_date)
      else
        scope
      end
    end

    private

    def start_date
      date_or_default(args[:since])
    end

    def end_date
      date_or_default(args[:until])
    end

    def date_or_default(date)
      Date.parse(date)
    rescue
      nil
    end
  end
end
