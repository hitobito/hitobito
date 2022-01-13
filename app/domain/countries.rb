# encoding: utf-8

#  Copyright (c) 2012-2015, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Countries

  module_function

  def codes
    ISO3166::Data.codes
  end

  def labels(lang)
    ISO3166::Country.translations(lang)
  end

  def label(country)
    c = ISO3166::Country.new(country)
    c ? c.translations[I18n.locale.to_s] || c.name.presence : country
  end

  def normalize(value)
    normalized = value

    downcased = value.to_s.strip.downcase
    if downcased.size > 2
      ISO3166::Country.translations(I18n.locale).each do |key, label|
        normalized = key if label.downcase == downcased
      end
    else
      normalized = value.to_s.strip.upcase
    end

    normalized
  end

  def swiss?(country)
    ['', 'ch'].include?(country.to_s.strip.downcase)
  end

end
