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
#  context_type          :string
#  key                   :string           not null
#  label                 :string           not null
#  placeholders_optional :string
#  placeholders_required :string
#  subject               :string
#  context_id            :bigint
#
# Indexes
#
#  index_custom_contents_on_context  (context_type,context_id)
#

class CustomContent < ActiveRecord::Base
  include Globalized
  translates :label, :subject
  translates_rich_text :body

  # specify validations for translated attributes explicitly
  validates :label, presence: true
  validates :label, :subject, length: {maximum: 255, allow_nil: true}
  # The custom content placeholders validator checks if the placeholder is either in the body or the subject of the custom content
  validates :body, length: {allow_nil: true, maximum: 2**16 - 1}, no_attachments: true, custom_content_placeholders: true
  validates_by_schema

  belongs_to :context, optional: true, polymorphic: true

  default_scope { where(context_id: nil, context_type: nil) }
  scope :in_context, ->(context) { unscoped.where(context: context) }

  class << self
    def get(key, context: nil)
      content = in_context(context).find_by(key: key)
      content || CustomContent.find_by!(key: key)
    end
  end

  def to_s(_format = :default)
    label
  end

  def placeholders_list
    @placeholders_list ||= placeholders_required_list + placeholders_optional_list
  end

  def placeholders_required_list
    as_list(custom_content_value(:placeholders_required))
  end

  def placeholders_optional_list
    as_list(custom_content_value(:placeholders_optional))
  end

  def placeholder_token(key)
    "{#{key}}"
  end

  def subject_with_values(placeholders = {})
    replace_placeholders(subject.dup.to_s.html_safe, placeholders)
  end

  def body_with_values(placeholders = {})
    # Consider the custom content as html safe before replacing the placeholders
    replace_placeholders(body.to_s.html_safe, placeholders)
  end

  def replace_placeholders(string, placeholders)
    check_placeholders_exist(placeholders)
    # Make sure the string is safe
    string = ERB::Util.html_escape(string)

    placeholders_list.each_with_object(string) do |placeholder, output|
      token = placeholder_token(placeholder)
      if output.include?(token)
        # We will escape the values from the placeholder unless the placeholder is html safe
        placeholder_value = ERB::Util.html_escape(placeholders.fetch(placeholder).to_s)
        output.gsub!(token, placeholder_value)
      end
    end
    # Gsub! turns the output into an unsafe string, so we need to mark it safe again
    string.html_safe
  end

  private

  def custom_content_value(field)
    if context
      CustomContent.find_by(key: key)&.public_send(field)
    else
      public_send(field)
    end
  end

  def as_list(placeholders)
    placeholders.to_s.split(",").collect(&:strip)
  end

  def check_placeholders_exist(placeholders)
    non_existing = (placeholders.keys - placeholders_list).presence
    if non_existing
      raise(ArgumentError,
        "Placeholder(s) #{non_existing.join(", ")} given, " \
        "but not defined for this custom content")
    end
  end
end
