# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module Export::Csv::Groups
  class List < Export::Csv::Base

    EXCLUDED_ATTRS = %w(lft rgt contact_id created_at updated_at deleted_at
                        creator_id updater_id deleter_id)

    self.model_class = Group

    def attributes
      (model_class.column_names - EXCLUDED_ATTRS).collect(&:to_sym)
    end

    class Row < Export::Csv::Row

      def type
        entry.class.label
      end

    end

    self.row_class = Row

  end
end
