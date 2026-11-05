# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: blocklist_entries
#
#  id           :bigint           not null, primary key
#  blocked_hash :string           not null
#  created_at   :datetime         not null
#  creator_id   :bigint
#  hashed_attrs :text             not null
#
# Indexes
#
#  index_blocklist_entries_on_blocked_hash_and_hashed_attrs  (blocked_hash,hashed_attrs) UNIQUE
#  index_blocklist_entries_on_creator_id                     (creator_id)
#
class BlocklistEntry < ApplicationRecord
  belongs_to :creator, class_name: "Person"

  serialize :hashed_attrs, type: Array, coder: NilArrayCoder

  attribute :person_id, :integer
  attr_reader :manual_person

  before_validation :calculate_blocked_hash, if: -> { new_record? && blocked_hash.blank? }
  after_create :create_entries_without_optional_attrs

  validates_by_schema except: :hashed_attrs
  validates :hashed_attrs, presence: true, if: -> { blocked_hash.present? }
  validate :assert_not_blocklisted, on: :create

  scope :matching, ->(blocked_hash, hashed_attrs) do
    where(blocked_hash:, hashed_attrs: hashed_attrs.map(&:to_s))
  end

  def person
    @person ||= Person.find_by(id: person_id) if person_id.present?
  end

  def manual_person_attributes=(attrs)
    @manual_person = Person.new(attrs)
  end

  def to_s
    "##{id}"
  end

  private

  def hashed_person
    person || manual_person
  end

  def detector
    @detector ||= Person::BlocklistDetector.new(hashed_person) if hashed_person
  end

  def calculate_blocked_hash
    return unless detector

    self.blocked_hash = detector.blocked_hash
    self.hashed_attrs = detector.hashed_attrs&.map(&:to_s)
  end

  def create_entries_without_optional_attrs
    return unless detector

    rows = detector.all_blocked_hashes.except(detector.hashed_attrs).map do |attrs, hash|
      {blocked_hash: hash, hashed_attrs: attrs.map(&:to_s), creator_id:, created_at:}
    end
    self.class.insert_all(rows, unique_by: [:blocked_hash, :hashed_attrs]) if rows.present?
  end

  def assert_not_blocklisted
    return if blocked_hash.blank? || hashed_attrs.blank?

    errors.add(:base, :already_blocklisted) if self.class.matching(blocked_hash, hashed_attrs).any?
  end
end
