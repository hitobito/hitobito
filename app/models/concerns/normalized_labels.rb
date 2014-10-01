# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# For a given label field, assert that always the same value is used for two values that
# differ only in the letter case. Additionally, cache all the existing labels of the
# corresponding table.
module NormalizedLabels
  extend ActiveSupport::Concern

  included do
    before_save :normalize_label
  end

  private

  # If a case-insensitive same label already exists, use this one
  def normalize_label
    return if label.blank?

    fresh = self.class.available_labels.none? do |l|
      equal = l.casecmp(label) == 0
      self.label = l if equal
      equal
    end
    self.class.sweep_available_labels if fresh
  end

  module ClassMethods
    def available_labels
      Rails.cache.fetch(labels_cache_key) do
        load_available_labels
      end
    end

    def sweep_available_labels
      Rails.cache.delete(labels_cache_key)
    end

    private

    def load_available_labels
      predefined_labels |
      base_class.order(:label).uniq.pluck(:label).compact
    end

    def predefined_labels
      []
    end

    def labels_cache_key
      "#{base_class.name}.Labels"
    end
  end


end
