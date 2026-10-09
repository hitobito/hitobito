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
#
# Indexes
#
#  index_blocklist_entries_on_blocked_hash  (blocked_hash) UNIQUE
#  index_blocklist_entries_on_creator_id    (creator_id)
#
class BlocklistEntry < ApplicationRecord
  belongs_to :creator, class_name: "Person", optional: true

  attribute :person_id, :integer
  attr_reader :manual_person

  before_validation :calculate_blocked_hash, if: -> { new_record? && blocked_hash.blank? }

  validate :assert_blocked_hash_present
  validate :assert_not_blocklisted, if: :new_record?

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

  def calculate_blocked_hash
    hashed_person = person || manual_person
    self.blocked_hash = Person::BlocklistDetector.new(hashed_person).blocked_hash if hashed_person
  end

  def assert_blocked_hash_present
    errors.add(:base, :person_missing) if blocked_hash.blank?
  end

  def assert_not_blocklisted
    errors.add(:base, :already_blocklisted) if self.class.exists?(blocked_hash: blocked_hash)
  end
end
