module Event::YearBasedPaging
  extend ActiveSupport::Concern
  included do
    attr_accessor :year_range
    helper_method :year_range
  end

  def set_year_vars
    this_year = Date.today.year
    @year_range = (this_year-2)...(this_year+3)
    @year = year_range.include?(params[:year].to_i) ? params[:year].to_i : this_year 
  end
end
