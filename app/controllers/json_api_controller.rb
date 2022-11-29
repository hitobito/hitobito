class JsonApiController < ApplicationController
  JsonApiUnauthorized

  include Graphiti::Rails

  def authenticate_person!(*args)
    super(*args)
  end

  rescue_from Exception do |e|
    handle_exception(e)
  end

  register_exception Graphiti::Errors::RecordNotFound,
    status: 404

  register_exception CanCan::AccessDenied,
    status: 403,
    title: I18n.t('errors.403.title'),
    message: ->(error) { I18n.t('errors.403.explanation') }

  register_exception CanCan::AccessDenied,
    status: 401,
    title: I18n.t('errors.401.title'),
    message: ->(error) { I18n.t('errors.401.explanation') }
end
