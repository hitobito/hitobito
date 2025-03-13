#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UpdatePeoplesPrimaryGroup < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      WITH single_group_people AS (
        SELECT
          people.id AS person_id,
          MIN(roles.group_id) AS group_id
        FROM
          people
        INNER JOIN
          roles AS roles
        ON
          people.id = roles.person_id
        WHERE
          people.primary_group_id IS NULL
        GROUP BY
          people.id
        HAVING
          COUNT(DISTINCT roles.group_id) = 1
      )
      UPDATE people
      SET primary_group_id = single_group_people.group_id
      FROM single_group_people
      WHERE people.id = single_group_people.person_id;
    SQL

  end
end
