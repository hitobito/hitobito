class MailingListsController < CrudController
  
  self.nesting = Group

  decorates :group
  
  prepend_before_filter :parent
  
  
  private
  
  alias_method :group, :parent
  
end