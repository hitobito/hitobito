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
    sleep 0.5
    @valid ||= rand(1000) # TODO
  end

  def invalid
    @invalid ||= total - valid
  end

  def total
    @total ||= valid + rand(100) # TODO
  end
end
