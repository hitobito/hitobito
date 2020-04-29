# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
class ErrorsController < ActionController::Base
  layout 'application'
  helper_method :current_user, :origin_user

  protect_from_forgery with: :exception

  def show
    status_code = params[:code] || 500
    formats = request.format.json? ? [:json] : [:html]
    render status_code.to_s, status: status_code, formats: formats
  end

  private

  def current_user
    false
  end

  def origin_user
    false
  end

end
