# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Messages::BulkMail < Message
  has_one :mail_log, foreign_key: :message_id

  before_create :set_message_recipients

  def set_message_recipients
    # do nothing for the moment
    # create entry for every recipient in the future
  end
end
