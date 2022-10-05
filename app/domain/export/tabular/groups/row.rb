# frozen_string_literal: true

#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Groups
  class Row < Export::Tabular::Row
    def type
      entry.class.label
    end

    def country
      entry.country_label
    end

    def phone_numbers
      entry.phone_numbers.map(&:to_s).join(', ')
    end

    def social_accounts
      entry.social_accounts.map(&:to_s).join(', ')
    end

    def member_count
      entry.people.distinct.count
    end
  end
end
