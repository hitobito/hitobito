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