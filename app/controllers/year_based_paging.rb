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
    @year_range ||= (year-2)..(year+1)
  end
  
  def default_year
    @default_year ||= Date.today.year
  end
end
