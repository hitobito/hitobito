class JsonApiController < ActionController::API
  include Authenticatable
  include Sentry
  
  class JsonApiUnauthorized < StandardError; end

  def authenticate_person!(*args)
    unless sign_in_person
      raise JsonApiUnauthorized
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

end
