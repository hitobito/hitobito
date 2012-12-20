module Sheet
  class MailingList < Base
    self.parent_sheet = Sheet::Group
    self.has_tabs = true
  end
end