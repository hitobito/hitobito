# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMissingIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index(:subscriptions, :mailing_list_id)
    add_index(:subscriptions, [:subscriber_id, :subscriber_type])

    add_index(:related_role_types, [:relation_id, :relation_type])
    add_index(:related_role_types, :role_type)

    add_index(:qualifications, :person_id)
    add_index(:qualifications, :qualification_kind_id)

    add_index(:people_filters, [:group_id, :group_type])

    add_index(:mailing_lists, :group_id)

    add_index(:events, :kind_id)
    add_index(:event_dates, :event_id)
    add_index(:event_questions, :event_id)
    add_index(:event_participations, :event_id)
    add_index(:event_participations, :person_id)

    add_index(:events_groups, [:event_id, :group_id], unique: true)

    add_index(:event_roles, :type)
    add_index(:event_roles, :participation_id)


    add_index(:event_kinds_prolongations, [:event_kind_id, :qualification_kind_id], unique: true, name: 'index_event_kinds_prolongations')
    add_index(:event_kinds_preconditions, [:event_kind_id, :qualification_kind_id], unique: true, name: 'index_event_kinds_preconditions')
    add_index(:event_kinds_qualification_kinds, [:event_kind_id, :qualification_kind_id], unique: true, name: 'index_event_kinds_qualification_kinds')

    add_index(:event_answers, [:participation_id, :question_id], unique: true)
  end
end
