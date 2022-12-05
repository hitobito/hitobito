# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApiController < ActionController::API
  before_action :set_default_locale

  include ActionController::Cookies
  include Localizable
  include Authenticatable
  include Sentry
  
  class JsonApiUnauthorized < StandardError; end

  def authenticate_person!(*args)
    if user_session?
      super(*args)
    else
      raise JsonApiUnauthorized unless api_sign_in
    end
  end

  register_exception CanCan::AccessDenied,
    status: 403, handler: Graphiti::Rails::ExceptionHandler,
    title: I18n.t('errors.403.title'),
    message: ->(error) { I18n.t('errors.403.explanation') }

  register_exception JsonApiUnauthorized,
    status: 401,  handler: Graphiti::Rails::ExceptionHandler,
    title: I18n.t('errors.401.title'),
    message: ->(error) { I18n.t('errors.401.explanation') }

  private

  def user_session?
    cookies['_session_id'].present?
  end

  # Sign in by deprecated user token is not supported by hitobito JSON API
  def deprecated_user_token_sign_in
    return nil
  end

  # set default locale to english for api
  def set_default_locale
    I18n.default_locale = :en
  end
end
