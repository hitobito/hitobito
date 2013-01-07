class MailingListsController < CrudController
  
  self.nesting = Group

  decorates :group, :mailing_list
  
  prepend_before_filter :parent
  
  
  private
  
  alias_method :group, :parent
  
end
