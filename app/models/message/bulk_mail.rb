# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Message::BulkMail < Message
  delegate :mail_from, to: :mail_log

  validates :uid, presence: true, uniqueness: true

  attr_readonly :uid

  before_validation :generate_uid, unless: :uid

  private

  def generate_uid
    self.uid = SecureRandom.hex(8)
  end

end
