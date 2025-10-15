# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::ManualDeletionsController < ApplicationController
  before_action :entry
  before_action :authorize_action
  before_action :ensure_rules
  helper_method :minimizable?, :render_error_section, :disable_delete?, :disable_minimize?
  respond_to :js, only: [:new]

  def authorize_action
    authorize!(:manually_delete_people, group)
  end

  def show
  end

  def minimize
    # With the :destroy permission, a user can be minimized despite errors
    if !minimizable? || (disable_minimize? && cannot?(:destroy, entry))
      raise StandardError.new("can not minimize")
    end

    People::Minimizer.new(entry).run

    redirect_to group_deleted_people_path(group), notice: t(".success", full_name: entry.full_name)
  end

  def delete
    # With the :destroy permission, a user can be deleted despite errors
    if disable_delete? && cannot?(:destroy, entry)
      raise StandardError.new("can not delete")
    end

    People::Destroyer.new(entry).run

    redirect_to group_deleted_people_path(group), notice: t(".success", full_name: entry.full_name)
  end

  private

  def ensure_rules
    @universal_errors = []
    @deletable_errors = []
    @minimizable_errors = []

    ensure_universal_rules
    ensure_deletable_rules
    ensure_minimizable_rules if minimizable?

    @all_errors = (@universal_errors + @deletable_errors + @minimizable_errors).uniq
  end

  def ensure_universal_rules
  end

  def ensure_deletable_rules
  end

  def ensure_minimizable_rules
    @minimizable_errors << t(".errors.already_minimized") if entry.minimized_at.present?
  end

  def minimizable?
    FeatureGate.enabled?("people.minimization")
  end

  def disable_delete?
    @universal_errors.any? || @deletable_errors.any?
  end

  def disable_minimize?
    @universal_errors.any? || @minimizable_errors.any?
  end

  def entry
    @entry ||= Group::DeletedPeople.deleted_for(group).find(params[:person_id]) # performance?
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
