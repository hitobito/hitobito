# Copyright (c) 2017-2024, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# Adds a tsvector column to each model that includes the FullTextSearchable module,
# enabling full-text search functionality. Also adds a GIN index for faster querying.

Rails.application.config.after_initialize do
  SearchColumnBuilder.new.run
end
