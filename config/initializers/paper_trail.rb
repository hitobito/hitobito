# frozen_string_literal: true

#  Copyright (c) 2020-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# make sure our version of paper trail version is used (app/models/paper_trail/version.rb)
require_dependency 'paper_trail/version'

# We don't want paper_trail to create versions on touch events
# default is: [create update destroy touch]
# When we don't define a local skip option for a model, we want updated_at
# to be ignored per default. When a model adds own skip options,
# updated_at is not in the defaults anymore and has to be added
# manually if it should be skipped
PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy],
  skip: %i[updated_at]
}
