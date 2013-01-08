module Sheet
  module Subscriber
    class Person < Base
      self.parent_sheet = Sheet::MailingList
    end
  end
end
