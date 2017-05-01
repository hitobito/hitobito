# encoding: utf-8

#  Copyright (c) 2017 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class LabelFormat::SettingsController < ApplicationController

  before_action :authorize

  def update
    current_user.update_column(:show_global_label_formats,
                               params[:show_global_label_formats].present?)
  end

  private

  def authorize
    authorize!(:update_settings, current_user)
  end

end
