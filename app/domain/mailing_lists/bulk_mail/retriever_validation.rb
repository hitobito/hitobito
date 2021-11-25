# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.



module MailingLists::BulkMail::RetrieverValidations

  def sender_allowed?
    return false unless valid_email?(sender_email)

    mailing_list.anyone_may_post ||
      sender_is_additional_sender? ||
      sender_is_group_email? ||
      sender_is_list_administrator? ||
      (mailing_list.subscribers_may_post? && sender_is_list_member?)
  end

  def valid_email?(email)
    email.present? && Truemail.valid?(email)
  end

end
