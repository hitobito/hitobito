# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Globalized::RichTextTranslation
  extend ActiveSupport::Concern

  included do
    class_attribute :rich_text_columns, default: []

    before_save :discard_blank_rich_texts
  end

  class_methods do
    def has_rich_texts(*columns)
      self.rich_text_columns = columns
      columns.each { |col| has_rich_text col.to_sym }
      default_scope { includes(*columns.map { |col| :"rich_text_#{col}" }) }
    end
  end

  def save_rich_texts
    discard_blank_rich_texts
    rich_texts.each { |rich_text| rich_text.save if rich_text.changed? }
  end

  private

  def discard_blank_rich_texts
    rich_text_columns.each do |col|
      rich_text = public_send(:"rich_text_#{col}")
      association(:"rich_text_#{col}").reset if rich_text&.new_record? && rich_text.blank?
    end
  end

  def rich_texts
    rich_text_columns.filter_map { |col| public_send(:"rich_text_#{col}") }
  end
end
