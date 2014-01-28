# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationController < ActionController::Base

  include DecoratesBeforeRendering
  include Userstamp

  alias_method :decorate, :__decorator_for__

  protect_from_forgery
  helper_method :current_user, :person_home_path

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: 'Sie sind nicht berechtigt, diese Seite anzuzeigen'
  end if Rails.env.production?

  before_filter :set_locale
  before_filter :authenticate_person!
  check_authorization unless: :devise_controller?


  private

  def current_person
    @current_person ||= super.tap do |user|
      Person::PreloadGroups.for(user)
    end
  end

  def current_user
    current_person
  end

  def person_home_path(person)
    group_person_path(person.default_group_id, person)
  end

  def set_locale
   I18n.locale = params[:locale] || cookies[:locale] || guess_locale || I18n.default_locale
   cookies[:locale] = { value: I18n.locale, expires: 1.year.from_now }
  end

  def default_url_options(options = {})
    if Settings.application.languages.to_hash.size > 1
      { locale: I18n.locale }
    else
      {}
    end
  end

  def guess_locale
    http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def set_stamper
    Person.stamper = current_user
  end

  def reset_stamper
    Person.reset_stamper
  end

  def authenticate_person_from_token!
    token = Devise.token_generator.digest(Person, :reset_password_token, params[:onetime_token])
    user = Person.find_or_initialize_with_error_by(:reset_password_token, token)

    if user.persisted? && user.reset_password_period_valid?
      user.clear_reset_password_token!
      sign_in user
    end
  end

end
