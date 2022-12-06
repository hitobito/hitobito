# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApiController < ActionController::API
  include GraphitiErrors

  rescue_from Exception do |e|
    handle_exception(e)
  end

  include ActionController::Cookies
  include Localizable
  include Authenticatable
  include Sentry
  
  class JsonApiUnauthorized < StandardError; end

  register_exception CanCan::AccessDenied,
    status: 403,
    title: 'Access denied',
    message: ->(error) { I18n.t('errors.403.explanation') }

  register_exception JsonApiUnauthorized,
    status: 401,
    title: 'Login required',
    message: ->(error) { I18n.t('errors.401.explanation') }

  register_exception ActiveRecord::RecordNotFound,
    status: 404,
    title: 'Resource not found',
    message: ->(error) { I18n.t('errors.404.explanation') }

  before_action :set_paper_trail_whodunnit

  def authenticate_person!(*args)
    if user_session?
      super(*args)
    else
      raise JsonApiUnauthorized unless api_sign_in
    end
  end

  private

  def user_session?
    cookies['_session_id'].present?
  end

  # Sign in by deprecated user token is not supported by hitobito JSON API
  def deprecated_user_token_sign_in
    return nil
  end

  # set default locale to english for api since machines prefer to
  # talk in english ;)
  def set_locale
    I18n.locale = available_locale!(params[:locale]) ||
      available_locale!(cookies[:locale]) ||
      :en
  end

  def application_languages
    @application_languages ||= begin
                                 languages = super.dup
                                 languages[:en] = 'English'
                                 languages
                               end
  end

  def user_for_paper_trail
    origin_user_id = session[:origin_user]
    origin_user_id || current_service_token&.to_s || oauth_token_user&.id || super
  end
end
