module Sheet
  module Subscriber
    class Group < Base
      self.parent_sheet = Sheet::MailingList
    end
  end
end
