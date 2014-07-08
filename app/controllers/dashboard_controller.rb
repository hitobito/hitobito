# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DashboardController < ApplicationController

  skip_before_action :authenticate_person!, only: :index
  skip_authorization_check only: :index

  respond_to :json

  def index
    authenticate_person! unless request.format.html?

    flash.keep
    if current_user
      redirect_to person_home_path(current_user, format: request.format.to_sym)
    else
      redirect_to new_person_session_path
    end
  end

end
