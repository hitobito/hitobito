# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleFilterCriterionsController < ApplicationController
  prepend Nestable
  prepend DryCrud::InstanceVariables

  self.nesting = Group
  respond_to :turbo_stream

  alias_method :group, :parent
  helper_method :entry, :group, :active_criterias
  skip_before_action :verify_authenticity_token

  CRITERIAS = %w[role attributes tag qualification]
  CRITERIAS_KEY = :people_filter_active_criterias

  def create
    authorize!(:new, entry)
    flash[CRITERIAS_KEY] = active_criterias + [params[:criterion]]
  end

  def destroy
    authorize!(:new, entry)
    flash[CRITERIAS_KEY] = active_criterias - [params[:criterion]]
  end

  private

  def entry = group.people_filters.build # NOTE: partials expect an people_filter as ane

  def active_criterias = flash[CRITERIAS_KEY].to_a
end
