module YearBasedPaging
  extend ActiveSupport::Concern
  
  included do
    helper_method :year_range
  end
  
  private

  def year
    @year ||= year_range.include?(params[:year].to_i) ? params[:year].to_i : default_year 
  end
  
  def year_range
    @year_range ||= (default_year-3)..(default_year+1)
  end
  
  def default_year
    @default_year ||= Date.today.year
  end
end
