# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The group types are part of the instance's structure definition, not of its data,
# and are therefore available without authentication.
class JsonApi::GroupTypesController < JsonApiController
  skip_before_action :authenticate_person!
  skip_authorization_check
end
