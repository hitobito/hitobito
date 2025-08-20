#  Copyright (c) 2012-2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Globalized
  extend ActiveSupport::Concern

  included do
    Rails.autoloaders.main.on_load(class_name) do
      translated_attribute_names.each do |attr|
        attributes = I18n.available_locales.map { |locale| :"#{attr}_#{locale}" }
          .filter { |a| validators_on(a).empty? }

        next if attributes.empty?

        validators_on(attr).each do |validator|
          next if validator.is_a?(ActiveRecord::Validations::PresenceValidator) || validator.is_a?(ActiveRecord::Validations::UniquenessValidator)

          attributes.each do |attribute|
            validates_with validator.class, validator.options.merge(attributes: attribute, unless: proc { attribute.end_with? "_#{I18n.locale}" })
          end
        end
      end

      def self.human_attribute_name(*options)
        attribute = options.first.to_sym
        if globalize_attribute_names.include? attribute
          attribute, locale = attribute.match(/^(.*)_([a-z]{2})$/).captures

          return "#{super(attribute, *options.drop(1))} (#{locale.upcase})"
        end
        super
      end
    end

    before_destroy :remember_translated_label

    class_attribute :list_alphabetically
    self.list_alphabetically = true
  end

  module ClassMethods
    include GlobalizeAccessors
    def translates(*columns)
      super(*columns, fallbacks_for_empty_translations: true)
      globalize_accessors
    end

    # Inspired by https://github.com/rails/actiontext/issues/32#issuecomment-450653800
    def translates_rich_text(*columns)
      translates(*columns)

      columns.each do |col|
        delegate "#{col}=", to: :translation
      end

      after_update do
        columns.each do |col|
          translations.each do |translation|
            translation.send(col).save if translation.send(col).changed?
          end
        end
      end

      const_get(:Translation).include globalized_rich_text_module(columns)
    end

    def list
      scope = left_join_translation
        .includes(:translations)
        .select("#{table_name}.*", translated_label_column)
        .distinct
      list_alphabetically ? scope.order("#{translated_label_column} NULLS LAST") : scope.order(:id)
    end

    def left_join_translation
      joins(
        <<-SQL
          LEFT JOIN #{translations_table_name} ON
          #{translations_table_name}.#{reflect_on_association(:translations).foreign_key} = #{table_name}.id
          AND #{translations_table_name}.locale = #{connection.quote(I18n.locale)}
        SQL
      )
    end

    private

    def translated_label_column
      "#{translations_table_name}.#{translated_attribute_names.first}"
    end

    def globalized_rich_text_module(columns)
      Module.new do
        extend ActiveSupport::Concern

        included do
          columns.each do |col|
            has_rich_text col.to_sym
          end

          default_scope { includes(*columns.map { |col| :"rich_text_#{col}" }) }
        end
      end
    end
  end

  private

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end
end
