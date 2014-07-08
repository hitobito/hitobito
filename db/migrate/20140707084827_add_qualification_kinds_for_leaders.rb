# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddQualificationKindsForLeaders < ActiveRecord::Migration
  def change
    create_table :event_kind_qualification_kinds do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_kind, null: false
      t.string :category, null: false
      t.string :role, null: false
    end

    join_query = "INNER JOIN event_kinds_%{postfix} ON event_kinds_%{postfix}.qualification_kind_id = qualification_kinds.id"

    qualifications = QualificationKind.joins(join_query % {postfix: 'qualification_kinds'}).
                                       pluck(:id, :event_kind_id) or []
    qualifications.each do |qualification_kind_id, event_kind_id|
      Event::KindQualificationKind.create!(event_kind_id: event_kind_id,
                                           qualification_kind_id: qualification_kind_id,
                                           category: 'qualification',
                                           role: 'participant')
    end

    preconditions = QualificationKind.joins(join_query % {postfix: 'preconditions'}).
                                      pluck(:id, :event_kind_id) or []
    preconditions.each do |qualification_kind_id, event_kind_id|
      Event::KindQualificationKind.create!(event_kind_id: event_kind_id,
                                           qualification_kind_id: qualification_kind_id,
                                           category: 'precondition',
                                           role: 'participant')
    end

    prolongations = QualificationKind.joins(join_query % {postfix: 'prolongations'}).
                                      pluck(:id, :event_kind_id) or []
    prolongations.each do |qualification_kind_id, event_kind_id|
      Event::KindQualificationKind.create!(event_kind_id: event_kind_id,
                                           qualification_kind_id: qualification_kind_id,
                                           category: 'prolongation',
                                           role: 'participant')
    end

    drop_table :event_kinds_qualification_kinds
    drop_table :event_kinds_prolongations
    drop_table :event_kinds_preconditions

    add_index(:event_kind_qualification_kinds, :category)
    add_index(:event_kind_qualification_kinds, :role)
  end
end
