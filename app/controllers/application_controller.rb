# encoding: utf-8

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationController < ActionController::Base

  include Authenticatable
  include DecoratesBeforeRendering
  include Stampable
  include Translatable
  include Localizable
  include ERB::Util
  include Sentry
  include ParamConverters
  include PaperTrailed

  # protect with null_session only in specific api controllers
  protect_from_forgery with: :exception

  helper_method :person_home_path
  helper_method :true?

  before_action :set_no_cache
  around_action :store_current_person

  class_attribute :skip_translate_inheritable

  alias decorate __decorator_for__

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json do
        render json: { status: 403, error: I18n.t('devise.failure.not_permitted_to_view_page') },
               status: 403
      end
      format.all do
        raise exception unless Rails.env.production?
        redirect_to root_path, alert: I18n.t('devise.failure.not_permitted_to_view_page')
      end
    end
  end

  if Rails.env.production?
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

  def store_current_person
    Auth.current_person = current_person
    yield
  ensure
    Auth.current_person = nil
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end
