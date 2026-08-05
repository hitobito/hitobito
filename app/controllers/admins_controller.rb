# frozen_string_literal: true

#  Copyright (c) 2026-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AdminsController < ApplicationController
  skip_authorization_check only: :show
  before_action :authorize_action, only: :show

  def show
  end

  private

  def authorize_action
    authorize!(:update_settings, current_person)
  end
end
