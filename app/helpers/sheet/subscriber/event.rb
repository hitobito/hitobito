module Sheet
  module Subscriber
    class Event < Base
      self.parent_sheet = Sheet::MailingList
    end
  end
end
