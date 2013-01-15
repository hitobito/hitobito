class MailingListsController < CrudController


  self.nesting = Group

  decorates :group, :mailing_list

  prepend_before_filter :parent


  def show
    @mailing_list = entry
  end

  private

  def list_entries
    super.order(:name)
  end


  alias_method :group, :parent

end
