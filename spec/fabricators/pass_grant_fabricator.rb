# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:pass_grant) do
  pass_definition
  grantor { Group.root }
  after_build do |grant|
    if grant.related_role_types.empty?
      grant.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end
end
