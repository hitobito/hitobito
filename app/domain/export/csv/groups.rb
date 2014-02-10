# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv
  module Groups

    def self.export_subgroups(group)
      Export::Csv::Generator.new(Subgroups.new(group)).csv
    end

  end
end
