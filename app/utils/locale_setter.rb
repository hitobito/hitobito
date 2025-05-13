#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LocaleSetter
  class << self
    def with_locale(locale: nil, person: nil)
      preferred_locale = locale || locale_from_person(person)

      I18n.with_locale(I18n.available_locales.include?(preferred_locale&.to_sym) ? preferred_locale : nil) do
        yield
      end
    end

    private

    def locale_from_person(person)
      return unless person

      person.respond_to?(:correspondence_language) ? person.correspondence_language : person.language
    end
  end
end
