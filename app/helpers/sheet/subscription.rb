module Sheet
  class Subscription < Base
    self.parent_sheet = Sheet::MailingList
  end
end