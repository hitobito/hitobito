#  Copyright (c) 2012-2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Globalized
  extend ActiveSupport::Concern

  included do
    before_destroy :remember_translated_label

    class_attribute :list_alphabetically
    self.list_alphabetically = true
  end

  module ClassMethods
    def translates(*columns)
      super(*columns, fallbacks_for_empty_translations: true)
      globalize_accessors
    end

    def globalize_accessors(options = {})
      options.reverse_merge!(locales: I18n.available_locales, attributes: translated_attribute_names)
      class_attribute :globalize_locales, :globalize_attribute_names, instance_writer: false

      self.globalize_locales = options[:locales]
      self.globalize_attribute_names = []

      each_attribute_and_locale(options) do |attr_name, locale|
        define_accessors(attr_name, locale)
      end
    end

    def localized_attr_name_for(attr_name, locale)
      "#{attr_name}_#{locale.to_s.underscore}"
    end

    # Inspired by https://github.com/rails/actiontext/issues/32#issuecomment-450653800
    def translates_rich_text(*columns)
      translates(*columns)

      columns.each do |col|
        delegate "#{col}=", to: :translation
      end

      after_update do
        columns.each do |col|
          translation.send(col).save if translation.send(col).changed?
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

    def define_accessors(attr_name, locale)
      attribute("#{attr_name}_#{locale}", ::ActiveRecord::Type::Value.new) if ::ActiveRecord::VERSION::STRING >= "5.0"
      define_getter(attr_name, locale)
      define_setter(attr_name, locale)
    end

    def define_getter(attr_name, locale)
      define_method localized_attr_name_for(attr_name, locale) do
        globalize.stash.contains?(locale, attr_name) ? globalize.send(:fetch_stash, locale, attr_name) : globalize.send(:fetch_attribute, locale, attr_name)
      end
    end

    def define_setter(attr_name, locale)
      localized_attr_name = localized_attr_name_for(attr_name, locale)

      define_method :"#{localized_attr_name}=" do |value|
        attribute_will_change!(localized_attr_name) if value != send(localized_attr_name)
        write_attribute(attr_name, value, locale: locale)
        translation_for(locale)[attr_name] = value
      end
      if respond_to?(:accessible_attributes) && accessible_attributes.include?(attr_name)
        attr_accessible :"#{localized_attr_name}"
      end
      globalize_attribute_names << localized_attr_name.to_sym
    end

    def each_attribute_and_locale(options)
      options[:attributes].each do |attr_name|
        options[:locales].each do |locale|
          yield attr_name, locale
        end
      end
    end
  end

  private

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end
end
