# frozen_string_literal: true

#  Copyright (c) 2025, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class ContactableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value && !value.is_a?(Contactable)
      record.errors[attribute] << I18n.t("errors.messages.invalid_contactable")
    end
  end
end
