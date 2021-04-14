# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class DateRange
    def initialize(user, params, options, scope)
      @user = user
      @params = params
      @options = options
      @scope = scope
    end

    def to_scope
      @scope.joins(:dates).between(start_date, end_date)
    end

    private

    def start_date
      date_or_default(@params.dig(:filter, :since), Time.zone.today.to_date)
    end

    def end_date
      date_or_default(@params.dig(:filter, :until), start_date.advance(years: 1))
    end

    def date_or_default(date, default)
      Date.parse(date)
    rescue
      default
    end
  end
end
