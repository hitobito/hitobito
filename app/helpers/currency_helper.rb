#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CurrencyHelper

  # redefine exising method, may also be done in tenants wagon
  def number_to_currency(number, options = {})
    unit = Settings.currency.unit
    ActiveSupport::NumberHelper.number_to_currency(number, options.reverse_merge(unit: unit))
  end

end

