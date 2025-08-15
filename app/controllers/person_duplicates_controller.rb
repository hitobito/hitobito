# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicatesController < ListController
  self.nesting = Group

  decorates :person_duplicates, :group

  private

  alias_method :group, :parent

  def authorize_class
    authorize!(:manage_person_duplicates, group)
  end

  def list_entries
    super.list.distinct.page(params[:page]).per(20).then do |scope|
      next scope unless params[:q]
      scope
        .joins("INNER JOIN people ON people.id IN (person_1_id, person_2_id)")
        .where(build_search_conditions)
    end
  end

  def build_search_conditions
    SearchStrategies::SqlConditionBuilder.new(
      params[:q],
      %w[people.first_name people.last_name]
    ).search_conditions
  end
end
