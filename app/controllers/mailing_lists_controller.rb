class MailingListsController < CrudController

  include RenderPeoplePdf
  include RenderPeopleCsv

  self.nesting = Group

  decorates :group, :mailing_list

  prepend_before_filter :parent


  def show
    @mailing_list = entry
    respond_to do |format|
      format.html
      format.pdf  { render_pdf(entry.people) }
      format.csv  { render_csv(entry.people, @group) }
    end
  end

  private

  def list_entries
    super.order(:name)
  end


  alias_method :group, :parent

end
