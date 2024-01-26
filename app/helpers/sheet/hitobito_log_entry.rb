# frozen_string_literal: true

module Sheet
  class HitobitoLogEntry < Sheet::Admin

    tab 'hitobito_log_entries.tabs.all', 'hitobito_log_entries_path', no_alt: true

    Hitobito.logger.categories.each do |category|
      tab category.capitalize, "hitobito_log_entries_path", params: { category: category }
    end

  end
end
