module Sheet
  module Subscriber
    class ExcludePerson < Base
      self.parent_sheet = Sheet::MailingList
    end
  end
end
