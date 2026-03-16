# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:pass) do
  person
  pass_definition
  state { :eligible }
  valid_from { Time.zone.today }
end
