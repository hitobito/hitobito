#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApiFilter < Event::Filter

  def initialize(group, params, year)
    @group = group
    @type = params[:type]
    @filter = params[:filter]
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    if @start_date.blank? && @end_date.blank?
      @start_date = Date.new(year, 1, 1)
      @end_date   = Date.new(year, 12, 31)
    end
  end

  def list_entries
    scope = Event.where(type: type)
                 .includes(:groups)
                 .with_group_id(relevant_group_ids)
                 .order_by_date
                 .preload_all_dates
                 .uniq


    end_date ? scope.between(start_date, end_date) : scope.upcoming(start_date)
  end

  def start_date
    @start_date.try(:beginning_of_day) || Time.zone.now.beginning_of_day
  end

  def end_date
    @end_date.try(:end_of_day)
  end

  private

  def parse_date(date_string)
    date_string.try(:to_date)
  rescue ArgumentError
    nil
  end

end
