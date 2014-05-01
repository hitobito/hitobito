# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Concerns
  module Localizable
    extend ActiveSupport::Concern

    included do
      before_action :set_locale
    end

    private

    def set_locale
      I18n.locale = available_locale!(params[:locale]) ||
                    available_locale!(cookies[:locale]) ||
                    guess_locale ||
                    I18n.default_locale
      cookies[:locale] = { value: I18n.locale, expires: 1.year.from_now }
    end

    def default_url_options(_options = {})
      if application_languages.size > 1
        { locale: I18n.locale }
      else
        {}
      end
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

  end
end
