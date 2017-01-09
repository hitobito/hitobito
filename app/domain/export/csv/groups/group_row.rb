# encoding: utf-8

#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

module Export::Csv::Groups
  class GroupRow < Export::Csv::Row

    def type
      entry.class.label
    end

    def country
      entry.country_label
    end

  end
end

