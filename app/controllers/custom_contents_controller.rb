class CustomContentsController < SimpleCrudController
  
  decorates :custom_content
  
  
  private
  
  def list_entries
    super.order(:label)
  end
  
end