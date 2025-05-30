# frozen_string_literal: true

#  Copyright (c) 2022-2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApiController < ActionController::API
  MEDIA_TYPE = "application/vnd.api+json"

  include GraphitiErrors

  rescue_from Exception do |e|
    # rescues and therefore skips error handling middleware
    handle_exception(e)

    # still notify of errors we have not handled explicitly
    unless registered_exception?(e)
      Airbrake.notify(e)
      Raven.capture_exception(e)
    end
  end

  include ActionController::Cookies
  include Localizable
  include Authenticatable
  include Sentry
  include PaperTrailed

  before_action :assert_media_type_json_api, only: [:update, :create]
  before_action :ensure_id_param_consistency, except: [:index, :create]

  class JsonApiUnauthorized < StandardError; end

  class JsonApiInvalidMediaType < StandardError; end

  register_exception ActionController::BadRequest,
    status: 400,
    title: "Bad request"

  register_exception Graphiti::Errors::UnknownAttribute,
    status: 400,
    title: "Unsupported attribute parameter",
    message: ->(error) { "The attribute parameter is not supported." }

  register_exception Graphiti::Errors::InvalidInclude,
    status: 400,
    title: "Unsupported include parameter",
    message: ->(error) { "The include parameter is not supported." }

  register_exception Graphiti::Errors::InvalidAttributeAccess,
    status: 400,
    title: "Unsupported filter parameter",
    message: ->(error) { "The filter parameter is not supported. Message: #{error.message}" }

  register_exception CanCan::AccessDenied,
    status: 403,
    title: I18n.t("errors.403.title"),
    message: ->(error) { I18n.t("errors.403.explanation") }

  register_exception JsonApiUnauthorized,
    status: 401,
    title: I18n.t("errors.401.title"),
    message: ->(error) { I18n.t("errors.401.explanation") }

  register_exception ActiveRecord::RecordNotFound,
    status: 404,
    title: I18n.t("errors.404.title"),
    message: ->(error) { I18n.t("errors.404.explanation") }

  register_exception Graphiti::Errors::RecordNotFound,
    status: 404,
    title: I18n.t("errors.404.title"),
    message: ->(error) { I18n.t("errors.404.explanation") }

  register_exception JsonApiInvalidMediaType,
    status: 415,
    title: "Invalid request format"

  register_exception Graphiti::Errors::UnsupportedPageSize,
    status: 422,
    title: I18n.t("errors.unsupported_page_size.title"),
    message: ->(error) {
               I18n.t("errors.unsupported_page_size.explanation",
                 size: error.instance_variable_get(:@size),
                 max: error.instance_variable_get(:@max))
             }

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
    if resource.update_attributes
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

  def authenticate_person!(*)
    if user_session?
      super
    else
      raise JsonApiUnauthorized unless api_sign_in
    end
  end

  private

  def user_session?
    person_signed_in?
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
    [
      self.class.name.delete_prefix("JsonApi::").delete_suffix("Controller").singularize,
      "Resource"
    ].join.constantize
  end

  def params
    # we don't need strong parameters for graphiti controllers
    super.permit!
  end

  def ensure_id_param_consistency
    # make sure both id params are the same
    # since we're checking permission based on
    # params :id
    data_id = params.dig(:data, :id).presence || return
    param_id = params[:id].presence || return

    raise ActionController::BadRequest if data_id.to_s != param_id.to_s
  end
end
