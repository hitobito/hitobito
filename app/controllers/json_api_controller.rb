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

  # set locale to en during class read to have error titles in english
  I18n.locale = :en

  register_exception CanCan::AccessDenied,
    status: 403,
    title: I18n.t('errors.403.title'),
    message: ->(error) { I18n.t('errors.403.explanation') }

  register_exception JsonApiUnauthorized,
    status: 401,
    title: I18n.t('errors.401.title'),
    message: ->(error) { I18n.t('errors.401.explanation') }

  register_exception ActiveRecord::RecordNotFound,
    status: 404,
    title: I18n.t('errors.404.title'),
    message: ->(error) { I18n.t('errors.404.explanation') }

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

  # set default locale to english for api
  def set_locale
    I18n.locale = available_locale!(params[:locale]) ||
      available_locale!(cookies[:locale]) ||
      :en
  end

  def application_languages
    languages = super 
    languages[:en] = 'English'
    languages
  end
end
