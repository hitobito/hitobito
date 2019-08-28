# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText < ActiveRecord::Base
  VIEW_KEYS = %w(index show new edit).freeze

  include Globalized
  translates :body

  validates :key, uniqueness: true
  validates_by_schema

  def to_s(_format = :default)
    return super() if key.nil?

    if VIEW_KEYS.include?(field)
      HelpText.human_attribute_name("key.#{field}", model: model.model_name.human)
    else
      "#{model.model_name.human}: #{model.human_attribute_name(field)}"
    end
  end

  private

  def model
    @model ||= key_parts.first.classify.constantize
  end

  def field
    @field ||= key_parts.second
  end

  def key_parts
    @key_parts ||= key.split('.', 2)
  end
end
