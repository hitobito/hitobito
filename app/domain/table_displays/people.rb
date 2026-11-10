# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module TableDisplays
  module People
    ALWAYS_SHOWN_ATTRS = [:first_name, :last_name, :nickname, :street, :housenumber,
      :address_care_of, :postbox, :zip_code, :town].freeze
  end
end
