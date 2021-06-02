# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::EventListing
  extend ActiveSupport::Concern

  DEFAULT_GROUPING = ->(event) { I18n.l(event.dates.first.start_at, format: :month_year) }

  included do
    helper_method :nav_left
  end

  private

  def grouped(scope, grouping = DEFAULT_GROUPING)
    EventDecorator.
      decorate_collection(scope).
      group_by(&grouping)
  end

  def nav_left
    @nav_left || params[:action]
  end
end
