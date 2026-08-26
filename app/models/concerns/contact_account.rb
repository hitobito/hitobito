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
    after_commit :reset_contactable_association_cache, on: :create,
      if: -> { category&.unique_per_contactable? }
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

  # The uniqueness check above reads contactable.public_send(assoc), which loads and
  # caches that association on the contactable as a side effect. Since validation runs
  # pre-save, that read can find this record missing (it doesn't exist in the DB yet)
  # and cache that -- stale, now that this record is saved -- state on the contactable
  # for the rest of its lifetime in memory.
  #
  # Only relevant when this record was created directly (e.g.
  # PhoneNumber.create!(contactable: person, ...)) rather than via the association
  # (e.g. person.phone_numbers.create!(...)): the latter keeps the association's target
  # in sync itself -- but only *after* the whole create! call (all callbacks included)
  # finishes, so that can't be detected from within a plain after_save (it would always
  # look "not yet synced" there, and resetting unconditionally was observed to make the
  # record show up twice the next time the association is read). Deferred to
  # after_commit so the association's own bookkeeping -- if any -- has already run by
  # the time this checks it.
  def reset_contactable_association_cache
    return unless contactable

    association = contactable.association(self.class.name.demodulize.tableize.to_sym)
    association.reset unless association.target.include?(self)
  end
end
