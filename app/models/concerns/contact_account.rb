#  Copyright (c) 2014-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAccount
  extend ActiveSupport::Concern
  # Still included for #predefined_labels/#translate_label, which
  # Dropdown::LabelItems and Contactable::Address (address_type-based PDF label
  # export) still read directly. Those -- and this include -- are retired once
  # they're migrated onto ContactAccountCategory in a later step of #4359; the new
  # category-based UI added here does not use this mechanism at all.
  include NormalizedI18nLabels

  included do
    class_attribute :value_attr

    self.labels_translations_key = "activerecord.attributes.contact_account.predefined_labels"

    has_paper_trail meta: {main: :contactable}

    belongs_to :contactable, polymorphic: true
    belongs_to :category, class_name: "ContactAccountCategory"

    validate :assert_category_unique_per_contactable, if: -> { category&.unique_per_contactable? }
  end

  def to_s(_format = :default)
    category_label.presence ? "#{value} (#{category_label})" : value.to_s
  end

  def value
    send(value_attr)
  end

  # label is a purely descriptive, optional free-text addition to category
  # (analogous to Role#label) and carries no business logic of its own.
  # Records not yet backfilled with a category (category_id still nil) fall back
  # to the old translated label, so they keep displaying correctly in the
  # meantime instead of showing a raw, untranslated string.
  def category_label
    return translated_label unless category

    [category.to_s, label.presence].compact.join(", ")
  end

  private

  # Checked against the contactable's in-memory association rather than a fresh DB
  # query, so a sibling marked for destruction in the same nested-attributes submit
  # (e.g. "replace this entry with a new one under the same category") is correctly
  # excluded, matching how ActiveRecord's own autosave validation treats siblings.
  def assert_category_unique_per_contactable
    return unless contactable

    siblings = contactable.public_send(self.class.name.demodulize.tableize)
    duplicate = siblings.find do |sibling|
      sibling != self && !sibling.marked_for_destruction? && sibling.category_id == category_id
    end
    errors.add(:category, :already_assigned, category: duplicate.category.to_s) if duplicate
  end
end
