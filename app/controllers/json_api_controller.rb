class JsonApiController < ActionController::API
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

  def api_params
    params.permit(filter: {}, sort: {}, page: {})
  end
end
