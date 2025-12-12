# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class BackgroundJobLogEntry < ApplicationRecord
  validates_by_schema

  store :payload, coder: JSON
end
