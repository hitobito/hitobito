#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class PublicColumn < Column

    def required_permission(attr)
      :show
    end

    def required_model_attrs(attr)
      [resolve_database_column(attr)]
    end

    def render(attr)
      super do |target, target_attr|
        template.format_attr(target, target_attr) if target.respond_to?(target_attr)
      end
    end

    def sort_by(attr)
      resolve_database_column(attr)
    end
  end
end
