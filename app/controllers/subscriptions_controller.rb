class SubscriptionsController < CrudController
  
  self.nesting = Group, MailingList
  
  decorates :group
  
  prepend_before_filter :parent
  
  
  
  alias_method :mailing_list, :parent
  
  def authorize!(action, *args)
    if :index == action
      super(:index_subscriptions, mailing_list)
    else
      super
    end
  end
end