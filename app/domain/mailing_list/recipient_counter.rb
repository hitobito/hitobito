#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingList::RecipientCounter

  def initialize(mailing_list, message_type, households = false)
    @mailing_list = mailing_list
    @message_type = message_type
    @households = households
  end

  def valid
    @valid ||= case @message_type
               when Message::Letter.name, Message::LetterWithInvoice.name
                 @households ?
                     @mailing_list.household_count(Person.with_address) :
                     @mailing_list.people_count(Person.with_address)
               when Message::TextMessage.name
                 @mailing_list.people_count(Person.with_mobile)
               else
                 @mailing_list.people_count
               end
  end

  def invalid
    @invalid ||= total - valid
  end

  def total
    @total ||= @households ?
                   @mailing_list.household_count :
                   @mailing_list.people_count
  end
end
