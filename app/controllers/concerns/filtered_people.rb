# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

# collect everything needed to filter people in a group with People::Filter::List
#
# the most common approach is wrapped in all_filtered_or_listed_people. if that
# does not fit, implement the same ideas directly in your controller
#
# depends on methods to determine the current user and group
module FilteredPeople
  extend ActiveSupport::Concern
  include ParamConverters # for list_param

  included do
    helper_method :list_filter_args, :list_filter_params
  end

  private

  def all_filtered_or_listed_people
    if params[:ids] == "all"
      params.delete(:ids)

      @people_ids = %w[all]
      person_filter.entries
    else
      person_filter.accessible_scope.where(id: list_param(:ids)).distinct
    end
  end

  def person_filter
    @person_filter ||= Person::Filter::List.new(
      group, current_user, list_filter_args, accessibles_class
    )
  end

  def list_filter_args
    if params[:filter_id].present?
      # DB-Stored filter with prepared params
      PeopleFilter.for_group(group).where(visible: true).find(params[:filter_id]).to_params
    else
      # ad-hoc/unsaved filter or nothing
      params
    end
  end

  def list_filter_params
    params.permit(:filter_id, :range, filters: {}).to_h
  end

  def accessibles_class = nil # uses PersonReadables by default
end
