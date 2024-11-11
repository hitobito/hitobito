# frozen_string_literal: true

#  Copyright (c) 2020-2024, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sjas.

previous = ActiveRecord::Migration.verbose
ActiveRecord::Migration.verbose = false

SearchColumnBuilder.new.run

ActiveRecord::Migration.verbose = previous

[
  Person,
  Group,
  Role
].each(&:reset_column_information)
