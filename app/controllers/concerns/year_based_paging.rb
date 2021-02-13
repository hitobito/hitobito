# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module YearBasedPaging
  extend ActiveSupport::Concern

  included do
    helper_method :year_range, :year, :default_year
  end

  private

  def year
    @year ||= params[:year].to_i > 0 ? params[:year].to_i : default_year
  end

  def year_range
    @year_range ||= (year - 2)..(year + 1)
  end

  def year_filter
    date = Date.new(year, 1, 1)
    date.beginning_of_year..date.end_of_year
  end

  def default_year
    @default_year ||= Time.zone.today.year
  end
end
