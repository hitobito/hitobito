# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class PrimaryGroupColumn < TableDisplays::Column
    def required_model_attrs(attr)
      []
    end

    def required_model_includes(attr)
      [:primary_group]
    end

    def render(attr)
      super do |person|
        primary_group(person)
      end
    end

    def required_permission(attr)
      :show
    end

    private

    def allowed_value_for(target, target_attr, &block)
      primary_group(target)
    end

    def primary_group(person)
      person.primary_group&.name
    end
  end
end
