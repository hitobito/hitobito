# frozen_string_literal: true

#  Copyright (c) 2012-2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class RelatedGroupRoles

    def initialize(group_id, list_filter_args)
      @group = Group.find(group_id)
      @list_filter_args = list_filter_args
    end

    def as_options
      { restrict_to_roles: role_sti_names,
        restrict_to_group_ids: group_ids }
    end

    private

    def group_ids
      [@group.id]
    end

    def role_sti_names
      @group.role_types.collect(&:sti_name)
    end

  end
end
