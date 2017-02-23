# encoding: utf-8

#  Copyright (c) 2012-2016, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class LabelFormat::SettingsController < ApplicationController
  before_action :authorize
  
  def update
    user.update_column(:show_global_label_formats, params[:show_global_label_formats].present?)
  end

  private

  def user
    current_user
  end

  def authorize
    authorize!(:label_format_settings, current_user)
  end
end
