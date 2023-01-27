# frozen_string_literal: true

#  Copyright (c) 2022-2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApiController < ActionController::API
  MEDIA_TYPE = 'application/vnd.api+json'

  include GraphitiErrors

  rescue_from Exception do |e|
    handle_exception(e)
  end

  include ActionController::Cookies
  include Localizable
  include Authenticatable
  include Sentry
  include PaperTrailed

  before_action :assert_media_type_json_api, only: [:update, :create]

  class JsonApiUnauthorized < StandardError; end
  class JsonApiInvalidMediaType < StandardError; end

  register_exception ActionController::BadRequest,
    status: 400,
    title: 'Bad request'

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

  register_exception JsonApiInvalidMediaType,
    status: 415,
    title: 'Invalid request format'

  register_exception Graphiti::Errors::UnsupportedPageSize,
    status: 422,
    title: I18n.t('errors.unsupported_page_size.title'),
    message: ->(error) { I18n.t('errors.unsupported_page_size.explanation',
                                size: error.instance_variable_get(:@size),
                                max: error.instance_variable_get(:@max)) }

  def index
    resources = resource_class.all(params)
    render(jsonapi: resources)
  end

  def show
    resource = resource_class.find(params)
    render(jsonapi: resource)
  end

  def create
    resource = resource_class.build(params)
    if resource.save
      render jsonapi: resource, status: :created
    else
      render jsonapi_errors: resource
    end
  end

  def update
    resource = resource_class.find(params)
    if resource.update_attributes # rubocop:disable Rails/ActiveRecordAliases
      render jsonapi: resource
    else
      render jsonapi_errors: resource
    end
  end

  def destroy
    resource = resource_class.find(params)
    if resource.destroy
      render jsonapi: {meta: {}}, status: :ok
    else
      render jsonapi_errors: resource
    end
  end


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
    nil
  end

  # protecting from CSRF attacks
  def assert_media_type_json_api
    return if request.content_type == MEDIA_TYPE

    raise JsonApiInvalidMediaType
  end

  def resource_class
    [self.class.name.delete_prefix("JsonApi::").delete_suffix("Controller").singularize, "Resource"].join.constantize
  end
end
