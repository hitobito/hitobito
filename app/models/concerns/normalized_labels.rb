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

    self.class.used_labels.find do |l|
      equal = l.casecmp(label) == 0
      self.label = l if equal
      equal
    end
  end

  module ClassMethods
    def available_labels = predefined_labels

    def used_labels = predefined_labels | labels_from_db

    private

    def predefined_labels = []

    def labels_from_db = base_class.order(:label).distinct.pluck(:label).compact
  end
end
