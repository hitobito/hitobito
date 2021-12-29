# encoding: utf-8

#  Copyright (c) 2021, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::RecipientCountsReflex < ApplicationReflex
  include ParamConverters

  # TODO authorization?
  # skip_authorization_check

  def count
    @household = true?(element.value)
    @recipient_count = recipient_counter.valid
  end

  def init_count(household)
    @household = household
    @recipient_count = recipient_counter.valid
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(element.dataset[:id])
  end

  def message_type
    element.dataset[:message_type]
  end

  def recipient_counter
    @recipient_counter ||= MailingList::RecipientCounter.new(mailing_list, message_type, @households)
  end

end
