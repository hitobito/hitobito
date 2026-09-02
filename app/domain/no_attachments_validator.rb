# frozen_string_literal: true

#  Copyright (c) 2020-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class NoAttachmentsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.body&.attachments&.any?
      record.errors.add(attribute, I18n.t("errors.messages.attachments_not_allowed"))
    end
  end
end
