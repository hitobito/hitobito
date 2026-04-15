# Copyright (c) 2026, Schweizer Wanderwege. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module ShippablesHelper
  def format_shipping_method(model)
    message.shipping_method_label
  end
end
