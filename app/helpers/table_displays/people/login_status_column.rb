#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays::People
  class LoginStatusColumn < TableDisplays::Column

    def required_permission(attr)
      :show
    end

    def required_model_attrs(attr)
      attr
    end

    def value_for(object, attr)
      super do
        template.format_attr(object, attr) if object.respond_to?(attr)
      end
    end

    def sort_by(attr)
      nil
    end
  end
end
