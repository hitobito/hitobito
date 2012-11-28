class CustomContentsController < CrudController
  
  def update
    super(location: custom_contents_path)
  end
  
  
  private
  
  def list_entries
    super.order(:label)
  end
  
end