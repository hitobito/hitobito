class LabelFormatsController < CrudController

  self.sort_mappings = { dimensions: %w(count_horizontal count_vertical)}
  
  def create
    super(location: label_formats_path)
  end
  
  def update
    super(location: label_formats_path)
  end
  
  private
  
  def list_entries
    super.order(:name)
  end
  
end
