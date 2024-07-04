# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Localizable
  extend ActiveSupport::Concern

  included do
    around_action :set_locale, if: :multiple_languages?
  end

  private

  def set_locale
    previous_locale = I18n.locale
    I18n.locale = available_locale!(params[:locale]) ||
      available_locale!(cookies[:locale]) ||
      guess_locale ||
      default_locale
    cookies[:locale] = {value: I18n.locale, expires: 1.year.from_now}

    yield

    I18n.locale = previous_locale
  end

  def default_locale
    I18n.default_locale
  end

  def default_url_options(_options = {})
    multiple_languages? ? {locale: I18n.locale} : {}
  end

  def available_locale!(locale)
    if locale.present?
      application_languages.keys.collect(&:to_s).include?(locale) ? locale : nil
    end
  end

  def guess_locale
    http_accept_language.compatible_language_from(application_languages.keys)
  end

  def application_languages
    Settings.application.languages.to_hash
  end

  def multiple_languages?
    application_languages.keys.size > 1
  end
end
