# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Roles::TerminationsController < ApplicationController

  respond_to :js, only: [:new, :create]

  helper_method :role, :group, :entry

  before_action :authorize

  def create
    if entry.call
      flash[:notice] = t('roles/terminations.flash.success', date: l(entry.terminate_on))
      render js: "window.location='#{person_path(role.person_id)}'"
    else
      render :create, format: :js
    end
  end

  private

  def entry
    @entry ||= Roles::Termination.new(role: role, terminate_on: terminate_on)
  end

  def role
    @role ||= Role.find(params[:role_id])
  end

  def terminate_on
    role.delete_on.presence ||
      params.dig(:roles_termination, :terminate_on).presence ||
      Date.today.end_of_year
  end

  def authorize
    authorize!(:terminate, role)
  end

end
