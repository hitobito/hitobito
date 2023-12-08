# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::ManualDeletionsController < ApplicationController

  RECENT_EVENT_CUTOFF_DURATION = 10.years

  before_action :entry
  before_action :authorize_action
  before_action :ensure_rules
  respond_to :js, only: [:new]

  def authorize_action
    authorize!(:manually_delete_people, group)
  end

  def show; end

  def minimize
    raise StandardError.new('can not minimize') unless minimizeable?

    People::Minimizer.new(entry).run

    redirect_to group_deleted_people_path(group), notice: t('.success', full_name: entry.full_name)
  end

  def delete
    raise StandardError.new('can not delete') unless deleteable?

    People::Destroyer.new(entry).run

    redirect_to group_deleted_people_path(group), notice: t('.success', full_name: entry.full_name)
  end

  private

  def ensure_rules
    @deleteable_errors = []
    @minimizeable_errors = []

    ensure_universal_rules
    ensure_minimizeable_rules
    ensure_deleteable_rules

    @all_errors = (@deleteable_errors + @minimizeable_errors).uniq
  end

  def ensure_universal_rules
    errors = []

    if participated_in_recent_event?
      errors << t('.errors.participated_in_recent_event',
                  duration: RECENT_EVENT_CUTOFF_DURATION)
    end

    @deleteable_errors += errors
    @minimizeable_errors += errors
  end

  def ensure_minimizeable_rules
    @minimizeable_errors << t('.errors.already_minimized') if entry.minimized_at.present?
  end

  def ensure_deleteable_rules; end

  def minimizeable?
    @minimizeable_errors.none?
  end

  def deleteable?
    @deleteable_errors.none?
  end

  def participated_in_recent_event?
    Event.joins(:dates, :participations)
      .where('event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff',
             cutoff: RECENT_EVENT_CUTOFF_DURATION.ago)
      .where("event_participations.person_id = ?", entry.id)
      .any?
  end

  def entry
    @entry ||= Group::DeletedPeople.deleted_for(group).find(params[:person_id]) # performance?
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

end
