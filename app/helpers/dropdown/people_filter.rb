# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  # rubocop:disable Rails/HelperInstanceVariable
  class PeopleFilter < Base
    attr_reader :criterias

    ID = "filter-criteria-dropdown"

    delegate :t, :group_people_filter_criterion_path, to: :template

    def initialize(template, user, active_criterias)
      super(template, template.t("global.button.add"), :plus)
      @criterias = PeopleFilterCriterionsController::CRITERIAS - active_criterias

      init_items
    end

    def to_s
      super(id: ID) if items.any?
    end

    private

    def init_items
      criterias.each do |criterion|
        add_item(
          t("people_filters.#{criterion}.title"),
          group_people_filter_criterion_path(criterion:),
          id: "dropdown-option-#{criterion}",
          data: {turbo_method: :post}
        )
      end
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
