# frozen_string_literal: true

#  Copyright (c) 2024, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class RemovePeopleRelations < ActiveRecord::Migration[6.1]
  def up
    people_relation_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM people_relations")
    raise StandardError.new("There are still PeopleRelation records") unless people_relation_count.to_i.zero?

    drop_table(:people_relations)
  end
end
