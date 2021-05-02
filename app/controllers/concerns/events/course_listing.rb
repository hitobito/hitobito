# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::CourseListing
  extend ActiveSupport::Concern

  included do
    attr_reader :group_id, :since_date, :until_date
    helper_method :course_list_title, :group_id, :since_date, :until_date
  end

  private

  def set_filter_vars
    set_group_vars
    set_date_vars
    set_kind_category_vars
  end

  def course_list_title
    @course_list_title ||= begin
      return I18n.t('event.lists.courses.no_category') if @kind_category_id == '0'

      Event::KindCategory.find_by(id: @kind_category_id)&.label
    end
  end

  def set_group_vars
    if can?(:list_all, Event::Course)
      if params[:year].blank?
        params[:filter] = {}
        params[:filter][:group_ids] = [
          Events::Filter::Groups.new(
            course_filters.user, course_filters.params,
            course_filters.options, course_filters.to_scope
          ).default_user_course_group.try(:id)
        ]
      end
      @group_id = params.dig(:filter, :group_ids).to_a.first.to_i
    end
  end

  def set_date_vars
    @since_date = date_or_default(params.dig(:filter, :since), Time.zone.today.to_date)
    @until_date = date_or_default(params.dig(:filter, :until), @since_date.advance(years: 1))
    @since_date = I18n.l(@since_date)
    @until_date = I18n.l(@until_date)
  end

  def date_or_default(date, default)
    Date.parse(date)
  rescue
    default
  end

  def set_kind_category_vars
    @kind_category_id = params.dig(:category)
  end

end
