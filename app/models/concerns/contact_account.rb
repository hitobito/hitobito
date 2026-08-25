#  Copyright (c) 2014-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAccount
  extend ActiveSupport::Concern

  included do
    class_attribute :value_attr

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
  # category may still be nil here for an unsaved, not-yet-categorized record
  # (e.g. a new row in a form preview).
  def category_label
    [category&.to_s, label.presence].compact.join(", ")
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
