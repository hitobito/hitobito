# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require Rails.root.join("lib", "hitobito", "can_can", "active_record_adapter")
require Rails.root.join("lib", "hitobito", "can_can", "default_adapter")

CanCan.accessible_by_strategy = :subquery
