# frozen_string_literal: true

class CleanUpPortfolioItemAndServiceNames < ActiveRecord::Migration[7.1]
  class MigrationPortfolioItem < ActiveRecord::Base
    self.table_name = :portfolio_items
  end

  class MigrationService < ActiveRecord::Base
    self.table_name = :services
  end

  def up
    cleanup_model(MigrationPortfolioItem)
    cleanup_model(MigrationService)
  end

  private

  def cleanup_model(model_class)
    inconsistent_ids = []
    table = model_class.table_name

    model_class.find_each do |record|
      name = record.name.to_s.downcase
      if name.start_with?('old:') && record.active
        inconsistent_ids << record.id
      elsif name.start_with?('active:') && !record.active # rubocop:disable Lint/DuplicateBranch
        inconsistent_ids << record.id
      end
    end

    if inconsistent_ids.any?
      raise "Migration abgebrochen! Inkonsistenz in Tabelle '#{table}' bei IDs: #{inconsistent_ids.join(', ')}. " \
            "Der 'active'-Status passt nicht zum Namen-Präfix."
    end

    model_class.find_each do |record|
      clean_name = record.name.to_s.sub(/\A(old:|active:)\s*/i, '').strip

      record.update_column(:name, clean_name) if clean_name != record.name
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
