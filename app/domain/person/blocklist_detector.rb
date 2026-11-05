# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::BlocklistDetector
  class_attribute :hash_attrs, default: [:first_name, :last_name]
  class_attribute :optional_hash_attrs, default: [:birthday]

  attr_reader :record

  def self.all_hash_attrs
    hash_attrs + optional_hash_attrs
  end

  def initialize(record)
    @record = record
  end

  def blocklisted?
    blocklist_entry.present?
  end

  def blocklist_entry
    BlocklistEntry.matching(blocked_hash, hashed_attrs).first if any_value_present?
  end

  def blocked_hash
    hash_for(hashed_attrs) if any_value_present?
  end

  def hashed_attrs
    hash_attrs + present_optional_attrs if any_value_present?
  end

  def all_blocked_hashes
    return {} unless any_value_present?

    0.upto(present_optional_attrs.size)
      .flat_map { |count| present_optional_attrs.combination(count).to_a }
      .map { |optional| hash_attrs + optional }
      .index_with { |attrs| hash_for(attrs) }
  end

  private

  def any_value_present?
    normalized_values.values.any?(&:present?)
  end

  def present_optional_attrs
    optional_hash_attrs.select { |attr| normalized_values[attr].present? }
  end

  def hash_for(attrs)
    Digest::MD5.hexdigest(".#{normalized_values.values_at(*attrs).join(".")}")
  end

  def normalized_values
    @normalized_values ||= self.class.all_hash_attrs.index_with do |attr|
      normalize(attr, record.public_send(attr))
    end
  end

  def normalize(attr, value)
    case value
    when Date, Time then value.strftime("%Y-%m-%d %H:%M:%S")
    else value.to_s.strip.downcase.tr(".", "_")
    end
  end
end
