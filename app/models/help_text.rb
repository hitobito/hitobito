# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText < ActiveRecord::Base
  VIEW_KEYS = %w(index show new edit).freeze

  include Globalized
  translates :body

  validates_by_schema

  def to_s(_format = :default)
    return super() if key.nil?

    "#{human_entry_class}: #{key_human}"
  end

  def dom_key
    key.gsub('/', '-').gsub('.', '--')
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
    controller = controller_name.classify.constantize.model_name.human
    entry = entry_class.classify.constantize.model_name.human
    controller == entry ? controller : "#{controller} (#{entry})"
  end

  def key_human
    if key.starts_with?('action.')
      HelpText.human_attribute_name("key.#{key_identifier}", model: entry_class)
    else
      "Feld «#{entry_klass.human_attribute_name(key_identifier)}»"
    end
  end

  private

  def entry_klass
    entry_class.classify.constantize
  end

  def human_entry_class
    entry_klass.model_name.human
  end

  def key_identifier
    key.split('.').second
  end
end
