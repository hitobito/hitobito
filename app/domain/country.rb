# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Country
  SWISS_NEIGHBOURS = %w[AT DE FR IT LI].freeze

  attr_reader :country_code

  def initialize(country_code)
    @country_code = country_code
    @country = ISO3166::Country[country_code]
  end

  def name(locale = I18n.locale)
    return country_code unless @country

    @country.translations[locale.to_s] ||
      @country.common_name ||
      @country.iso_short_name
  end

  def postal_name
    name(postal_locale).upcase
  end

  private

  def postal_locale
    return :en unless SWISS_NEIGHBOURS.include?(@country&.alpha2)

    @country.languages_official.first
  end
end
