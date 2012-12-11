class LabelFormatsController < SimpleCrudController

  self.sort_mappings = { dimensions: %w(count_horizontal count_vertical)}
  

  private
  
  def list_entries
    super.order(:name)
  end
  
end
