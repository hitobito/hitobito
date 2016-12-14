class LabelFormat::SettingsController < ApplicationController
  before_action :authorize
  
  def update
    if params[:display_only_own_label_formats].blank?
      user.update!(display_only_own_label_formats: false)
    else
      user.update!(display_only_own_label_formats: true)
    end
  end

  private

  def user
    current_user
  end

  def authorize
    authorize!(:label_format_settings, current_user)
  end
end
