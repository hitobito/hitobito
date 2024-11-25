# frozen_string_literal: true

#  Copyright (c) 2017-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MoneyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless (value / 0.05).frac == 0.0
      record.errors[attribute] << I18n.t("errors.messages.invalid_money")
    end
  end
end
