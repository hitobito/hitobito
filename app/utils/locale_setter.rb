#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LocaleSetter
  class << self
    def with_locale(locale: nil, person: nil)
      preferred_locale = locale || locale_from_person(person)

      # rubocop:todo Layout/LineLength
      I18n.with_locale(I18n.available_locales.include?(preferred_locale&.to_sym) ? preferred_locale : nil) do
        # rubocop:enable Layout/LineLength
        yield
      end
    end

    private

    def locale_from_person(person)
      return unless person

      # rubocop:todo Layout/LineLength
      person.respond_to?(:correspondence_language) ? person.correspondence_language : person.language
      # rubocop:enable Layout/LineLength
    end
  end
end
