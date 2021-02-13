# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string(255)      not null
#  placeholders_required :string(255)
#  placeholders_optional :string(255)
#

class CustomContent < ActiveRecord::Base

  include Globalized
  translates :label, :subject
  translates_rich_text :body

  # specify validations for translated attributes explicitly
  validates :label, presence: true
  validates :label, :subject, length: { maximum: 255, allow_nil: true }
  validates :body, length: { allow_nil: true, maximum: 2**16 - 1 }, no_attachments: true
  validates_by_schema

  validate :assert_required_placeholders_are_used

  class << self
    def get(key)
      find_by!(key: key)
    end
  end

  def to_s(_format = :default)
    label
  end

  def placeholders_list
    @placeholders_list ||= placeholders_required_list + placeholders_optional_list
  end

  def placeholders_required_list
    as_list(placeholders_required)
  end

  def placeholders_optional_list
    as_list(placeholders_optional)
  end

  def placeholder_token(key)
    "{#{key}}"
  end

  def subject_with_values(placeholders = {})
    replace_placeholders(subject.dup, placeholders)
  end

  def body_with_values(placeholders = {})
    replace_placeholders(body.to_s, placeholders)
  end

  private

  def replace_placeholders(string, placeholders)
    check_placeholders_exist(placeholders)

    placeholders_list.each_with_object(string) do |placeholder, output|
      token = placeholder_token(placeholder)
      if output.include?(token)
        output.gsub!(token, placeholders.fetch(placeholder))
      end
    end
  end

  def as_list(placeholders)
    placeholders.to_s.split(",").collect(&:strip)
  end

  def assert_required_placeholders_are_used
    placeholders_required_list.each do |placeholder|
      unless [subject, body.to_s].any? { |str| str.to_s.include?(placeholder_token(placeholder)) }
        errors.add(:body, :placeholder_missing, placeholder: placeholder_token(placeholder))
      end
    end
  end

  def check_placeholders_exist(placeholders)
    non_existing = (placeholders.keys - placeholders_list).presence
    if non_existing
      raise(ArgumentError,
            "Placeholder(s) #{non_existing.join(', ')} given, " \
            "but not defined for this custom content")
    end
  end
end
