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
