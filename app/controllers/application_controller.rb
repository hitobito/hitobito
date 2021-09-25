# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationController < ActionController::Base

  include DecoratesBeforeRendering
  include Userstamp
  include Translatable
  include Stampable
  include Localizable
  include Authenticatable
  include ERB::Util
  include Sentry
  include ParamConverters

  # protect with null_session only in specific api controllers
  protect_from_forgery with: :exception

  helper_method :person_home_path

  before_action :set_no_cache
  before_action :set_paper_trail_whodunnit

  class_attribute :skip_translate_inheritable

  alias decorate __decorator_for__

  if Rails.env.production?
    rescue_from CanCan::AccessDenied do |_exception|
      redirect_to root_path, alert: I18n.t('devise.failure.not_permitted_to_view_page')
    end

    rescue_from ActionController::UnknownFormat,
                ActionView::MissingTemplate,
                with: :not_found
  end

  def person_home_path(person, options = {})
    group_person_path(person.default_group_id, person, options)
  end

  private

  def fetch_person
    if current_person.roles.present?
      group.people.find(params[:id])
    else
      group
      Person.find(params[:id])
    end
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def set_no_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def html_request?
    request.formats.any? { |f| f.html? || f == Mime::ALL }
  end

  def user_for_paper_trail
    origin_user_id = session[:origin_user]
    origin_user_id ? origin_user_id : super
  end

  def current_ability
    @current_ability ||= if current_user
                           Ability.new(current_user)
                         elsif current_service_token
                           TokenAbility.new(current_service_token)
                         elsif current_oauth_token
                           DoorkeeperTokenAbility.new(current_oauth_token)
                         end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end
