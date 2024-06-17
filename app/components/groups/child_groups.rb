# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and
#  licensed under the Affero General Public License version 3 or later. See the
#  COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::ChildGroups < ApplicationComponent
  def initialize(sub_groups:)
    super
    @sub_groups = sub_groups
  end
end
