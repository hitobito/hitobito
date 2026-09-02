#  Copyright (c) 2014-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAccount
  extend ActiveSupport::Concern
  include NormalizedI18nLabels

  included do
    class_attribute :value_attr

    self.labels_translations_key = "activerecord.attributes.contact_account.predefined_labels"

    has_paper_trail meta: {main: :contactable}

    belongs_to :contactable, polymorphic: true

    validates :label, presence: true
    after_validation :mirror_label_errors_to_translated_label
  end

  def to_s(_format = :default)
    "#{value} (#{label})"
  end

  def value
    send(value_attr)
  end

  private

  # The form field is bound to translated_label (a virtual attribute writing through to
  # label), so errors added to :label alone are not shown next to that field.
  def mirror_label_errors_to_translated_label
    errors[:label].each { |message| errors.add(:translated_label, message) }
  end
end
