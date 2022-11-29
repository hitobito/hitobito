class JsonApiController < ApplicationController
  class JsonApiUnauthorized < StandardError; end

  include Graphiti::Rails

  def authenticate_person!(*args)
    unless sign_in
      raise JsonApiUnauthorized
    end
  end

  rescue_from Exception do |e|
    handle_exception(e)
  end

  register_exception JsonApiUnauthorized,
    status: 401,
    title: I18n.t('errors.401.title'),
    message: ->(error) { I18n.t('errors.401.explanation') }

  register_exception CanCan::AccessDenied,
    status: 403,
    title: I18n.t('errors.403.title'),
    message: ->(error) { I18n.t('errors.403.explanation') }

  ## TODO: customize and test
  # register_exception Graphiti::Errors::RecordNotFound,
    # status: 404
end
