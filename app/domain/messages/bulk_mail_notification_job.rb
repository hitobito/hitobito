# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class Messages::BulkMailNotificationJob

  def perform
    # send mail to senders who aren't allowed to send from a specific mailing list
  end

end
