# encoding: utf-8

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
      self::Translation.schema_validations_config.auto_create = false
    end

    def list
      with_translations.
        order(translated_label_column).
        uniq
    end

    private

    def translated_label_column
      "#{reflect_on_association(:translations).table_name}.#{translated_attribute_names.first}"
    end
  end

  private

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end

end