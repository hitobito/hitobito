# Copyright (c) 2026, Schweizer Wanderwege. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module Shippable
  extend ActiveSupport::Concern

  SHIPPING_METHODS = %w[own normal priority].freeze
  SHIPPABLE_ATTRIBUTES = %i[shipping_method pp_post].freeze

  included do
    i18n_enum :shipping_method, SHIPPING_METHODS, scopes: true, queries: true, validations: false,
      i18n_prefix: "activerecord.attributes.message/letter.shipping_methods"
    validates :shipping_method, inclusion: {in: SHIPPING_METHODS}

    class_attribute :shippable_attributes, default: SHIPPABLE_ATTRIBUTES
  end

  def shippable_attribute?(attribute)
    shippable_attributes.include?(attribute)
  end

  def effective_shipping_method
    shippable_attribute?(:shipping_method) ? shipping_method : "own"
  end

  def effective_pp_post
    pp_post if shippable_attribute?(:pp_post)
  end

  def shipping_info?
    effective_shipping_method != "own" || effective_pp_post.to_s.strip.present?
  end
end
