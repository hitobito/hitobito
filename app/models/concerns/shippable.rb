# Copyright (c) 2026, Schweizer Wanderwege. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module Shippable
  extend ActiveSupport::Concern

  SHIPPING_METHODS = %w[own normal priority].freeze

  included do
    i18n_enum :shipping_method, SHIPPING_METHODS, scopes: true, queries: true,
      i18n_prefix: "activerecord.attributes.message/letter.shipping_methods"
  end
end
