# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :search_column do
  desc "Builds search_columns based on SEARCHABLE_ATTRS for PostgreSql Fulltext Search"
  task build: :environment do
    SearchColumnBuilder.new.run
  end
end
