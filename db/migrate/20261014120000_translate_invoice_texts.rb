#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TranslateInvoiceTexts < ActiveRecord::Migration[8.0]
  def up
    say_with_time("creating translation table for invoice configs") do
      InvoiceConfig.create_translation_table!(
        {payment_information: :text},
        {migrate_data: true, remove_source_columns: true}
      )
    end

    say_with_time("creating translation table for invoice articles") do
      InvoiceArticle.create_translation_table!(
        {name: :string, description: :text},
        {migrate_data: true, remove_source_columns: true}
      )
    end

    say_with_time("creating translation table for message templates") do
      MessageTemplate.create_translation_table!(
        {title: :string, body: :text},
        {migrate_data: true, remove_source_columns: true}
      )
    end

    add_column :invoice_run_translations, :description, :text
    add_column :invoice_run_translations, :payment_information, :text

    translate_invoice_item_descriptions
  end

  def down
    add_column :invoice_items, :description, :text
    copy_translations_to_source(:invoice_items, :invoice_item_translations,
      :invoice_item_id, [:description])
    remove_column :invoice_item_translations, :description

    remove_column :invoice_run_translations, :payment_information
    remove_column :invoice_run_translations, :description

    restore_source_column(:message_templates, :message_template_translations,
      :message_template_id, title: :string, body: :text)
    change_column_null :message_templates, :title, false
    restore_source_column(:invoice_articles, :invoice_article_translations,
      :invoice_article_id, name: :string, description: :text)
    change_column_null :invoice_articles, :name, false
    restore_source_column(:invoice_configs, :invoice_config_translations,
      :invoice_config_id, payment_information: :text)
  end

  private

  def translate_invoice_item_descriptions
    add_column :invoice_item_translations, :description, :text

    say_with_time("transferring invoice item descriptions into invoice_item_translations") do
      execute <<~SQL
        UPDATE invoice_item_translations t SET description = i.description
        FROM invoice_items i
        WHERE t.invoice_item_id = i.id AND t.locale = '#{I18n.default_locale}'
          AND i.description <> ''
      SQL
      execute <<~SQL
        INSERT INTO invoice_item_translations
          (invoice_item_id, locale, description, created_at, updated_at)
        SELECT i.id, '#{I18n.default_locale}', i.description, NOW(), NOW()
        FROM invoice_items i
        WHERE i.description <> '' AND NOT EXISTS (
          SELECT 1 FROM invoice_item_translations t
          WHERE t.invoice_item_id = i.id AND t.locale = '#{I18n.default_locale}'
        )
      SQL
    end

    remove_column :invoice_items, :description
  end

  def restore_source_column(table, translation_table, foreign_key, columns)
    columns.each { |column, type| add_column table, column, type }
    copy_translations_to_source(table, translation_table, foreign_key, columns.keys)
    drop_table translation_table
  end

  def copy_translations_to_source(table, translation_table, foreign_key, columns)
    assignments = columns.map do |column|
      <<~SQL
        #{column} = (
          SELECT t.#{column} FROM #{translation_table} t
          WHERE t.#{foreign_key} = #{table}.id AND t.#{column} <> ''
          ORDER BY t.locale = '#{I18n.default_locale}' DESC, t.id
          LIMIT 1
        )
      SQL
    end
    execute "UPDATE #{table} SET #{assignments.join(", ")}"
  end
end
