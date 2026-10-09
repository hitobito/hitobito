# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::BlocklistDetector
  class_attribute :hash_attrs, default: [:first_name, :last_name, :birthday]

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def blocklisted?
    hash = blocked_hash
    hash.present? && BlocklistEntry.exists?(blocked_hash: hash)
  end

  def blocked_hash
    parts = hash_parts
    Digest::MD5.hexdigest(".#{parts.join(".")}") if parts.present?
  end

  private

  def hash_parts
    hash_attrs.map { |attr| normalize(record.public_send(attr)) }.compact_blank
  end

  def normalize(value)
    case value
    when Date, Time then value.strftime("%Y-%m-%d %H:%M:%S")
    when String then value.strip.downcase
    else value&.to_s
    end
  end
end
