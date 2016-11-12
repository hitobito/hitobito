#  Copyright (c) 2012-2016, Puzzle ITC GmbH. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Documentation
  module PermissionsHelper

    def human_permission(permission)
      t("activerecord.attributes.role.class.permission.#{permission}.short", default: permission)
    end

    def human_permission_description(permission)
      t("activerecord.attributes.role.class.permission.#{permission}.description", default: '')
    end

    def human_action(action)
      t("documentation.permissions.abilities.actions.#{action}")
    end

    def human_constraint(constraint)
      t("documentation.permissions.abilities.constraints.#{constraint}")
    end

  end
end
