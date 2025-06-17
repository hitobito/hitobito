# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class People::DuplicateConditions
  ATTRIBUTES = [
    :first_name,
    :last_name,
    :company_name,
    :zip_code,
    :birthday,
    :email
  ]

  def initialize(attrs)
    @attrs = attrs.symbolize_keys.slice(*ATTRIBUTES)
    @attrs[:birthday] = parse_birthday
    @attrs.compact_blank!
  end

  def build
    [""].tap do |args|
      append_common_and_conditions(args)
      append_email_or_condition(args) if attrs[:email].present?
    end
  end

  private

  attr_reader :attrs

  def append_common_and_conditions(args)
    attrs.except(:email).each do |key, value|
      condition = args[0].present? ? " AND " : ""
      condition += if nullable?(key)
        "(#{key} = ? OR #{key} IS NULL)"
      else
        "#{key} = ?"
      end
      args[0] += condition
      args << value
    end
  end

  def append_email_or_condition(args)
    args[0] = if args[0].present?
      "(#{args[0]}) OR email = ?"
    else
      "email = ?"
    end
    args << attrs[:email]&.downcase
  end

  def parse_birthday
    ActiveRecord::Type::Date.new.cast(@attrs[:birthday].to_s)
  rescue ArgumentError
    nil
  end

  def nullable?(key)
    %i[first_name last_name company_name].exclude?(key)
  end
end
