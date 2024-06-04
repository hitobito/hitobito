#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Globalized

  extend ActiveSupport::Concern

  included do
    before_destroy :remember_translated_label
  end

  module ClassMethods
    def translates(*columns)
      super(*columns, fallbacks_for_empty_translations: true)
    end

    # Inspired by https://github.com/rails/actiontext/issues/32#issuecomment-450653800
    def translates_rich_text(*columns)
      translates(*columns)

      columns.each do |col|
        delegate col, to: :translation
        delegate "#{col}=", to: :translation
      end

      after_update do
        columns.each do |col|
          translation.send(col).save if translation.send(col).changed?
        end
      end

      const_get(:Translation).include globalized_translation(columns)
    end

    def list
      self.select("*").from(
        with_translations.select("#{self.table_name}.*", translated_label_column)
        .distinct_on(:id).unscope(:order), self.table_name
      ).order("#{self.table_name}.#{translated_attribute_names.first.to_s}")
    end

    private

    def translated_label_column
      "#{reflect_on_association(:translations).table_name}.#{translated_attribute_names.first}"
    end

    def globalized_translation(columns)
      Module.new do
        extend ActiveSupport::Concern

        included do
          columns.each do |col|
            has_rich_text col.to_sym
          end

          default_scope { includes(*columns.map { |col| "rich_text_#{col}".to_sym }) }
        end
      end
    end
  end

  private

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end

end
