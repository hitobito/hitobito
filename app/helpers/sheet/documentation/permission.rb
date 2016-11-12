# encoding: utf-8

#  Copyright (c) 2012-2016, Puzzle ITC GmbH. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Documentation
    class Permission < Sheet::Base
      tab 'documentation.permissions.roles.title',
      :documentation_permissions_roles_path

      tab 'documentation.permissions.abilities.title',
      :documentation_permissions_abilities_path

      def title
        I18n.t('documentation.permissions.title')
      end
    end
  end
end
