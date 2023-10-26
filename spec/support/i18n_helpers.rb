# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module I18nHelpers
  def with_translations(translations)
    translations.each do |locale, locale_translations|
      I18n.backend.store_translations(locale, locale_translations)
    end
    yield
  ensure
    I18n.reload!
  end
end
