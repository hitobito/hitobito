# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class HitobitoLogEntry < Base
    tab 'hitobito_log_entries.tabs.all', 'hitobito_log_entries_path', no_alt: true

    Hitobito.logger.categories.each do |category|
      tab category.capitalize, "#{category}_hitobito_log_entries_path"
    end
  end
end
