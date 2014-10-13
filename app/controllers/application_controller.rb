# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationController < ActionController::Base

  include Concerns::DecoratesBeforeRendering
  include Userstamp
  include Translatable
  include Concerns::Stampable
  include Concerns::Localizable
  include Concerns::Authenticatable
  include ERB::Util

  protect_from_forgery

  helper_method :person_home_path
  hide_action :person_home_path

  before_action :set_no_cache

  alias_method :decorate, :__decorator_for__

  if Rails.env.production?
    rescue_from CanCan::AccessDenied do |_exception|
      redirect_to root_path, alert: I18n.t('devise.failure.not_permitted_to_view_page')
    end

    rescue_from ActionController::UnknownFormat, with: :not_found
  end


  def person_home_path(person, options = {})
    group_person_path(person.default_group_id, person, options)
  end

  private

  def not_found
    fail ActionController::RoutingError, 'Not Found'
  end

  def set_no_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def html_request?
    request.format.html? || request.format == Mime::ALL
  end
end
