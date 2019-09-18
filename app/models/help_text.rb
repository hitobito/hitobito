# frozen_string_literal: true
# == Schema Information
#
# Table name: help_texts
#
#  id              :integer          not null, primary key
#  controller_name :string(255)      not null
#  entry_class     :string(255)
#  key             :string(255)      not null
#  created_at      :datetime
#  updated_at      :datetime
#


#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText < ActiveRecord::Base
  COLUMN_BLACKLIST = %w(id created_at updated_at deleted_at).freeze

  validates :key, uniqueness: { scope: :controller_name }
  validates :body, presence: true
  validates_by_schema

  include Globalized
  translates :body

  scope :list, -> { order(:controller_name) }

  validates_by_schema

  def to_s(_format = :default)
    return super() if key.nil?

    "#{model_human}: #{key_human}"
  end

  def dom_key
    key.gsub('/', '-').gsub('.', '--')
  end

  def field_keys
    (model.column_names - COLUMN_BLACKLIST).map { |column_name| "field.#{column_name}" }
  end

  def context
    "#{controller_name}--#{entry_class}"
  end

  def context=(new_context)
    c, e = new_context.split('--')
    self.controller_name = c
    self.entry_class = e
  end

  def context_human
    controller_human == model_human ? controller_human : "#{controller_human} (#{model_human})"
  end

  def key_human
    action_or_attribute = key.split('.').second
    if action_specific_help_text?
      HelpText.human_attribute_name("key.#{action_or_attribute}", model: entry_class)
    else
      "Feld «#{model.human_attribute_name(action_or_attribute)}»"
    end
  end

  private

  def controller
    @controller ||= controller_name.classify.constantize
  end

  def controller_human
    controller.model_name.human
  end

  def model
    @model ||= entry_class.classify.constantize
  end

  def model_human
    model.model_name.human
  end

  def action_specific_help_text?
    key.starts_with?('action.')
  end
end
