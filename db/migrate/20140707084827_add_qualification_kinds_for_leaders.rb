# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddQualificationKindsForLeaders < ActiveRecord::Migration

  class Updater < Struct.new(:postfix, :category, :migration)
    QUALIFICATION_KIND_IDS = QualificationKind.pluck(:id)
    EVENT_KIND_IDS = Event::Kind.pluck(:id)

    QUERY = "INNER JOIN event_kinds_%{postfix} ON event_kinds_%{postfix}.qualification_kind_id = qualification_kinds.id"

    def update
      records = query
      current_records = current(query)

      migration.say("rejecting #{records.size - current_records.size} #{category}")

      current_records.each do |qualification_kind_id, event_kind_id|
        Event::KindQualificationKind.create!(event_kind_id: event_kind_id,
                                            qualification_kind_id: qualification_kind_id,
                                            category: category.to_s,
                                            role: 'participant')
      end
    end

    private

    def query
      QualificationKind.joins(QUERY % { postfix: postfix }).pluck(:id, :event_kind_id) or []
    end

    def current(list)
      list.select do |qualification_kind_id, event_kind_id|
        QUALIFICATION_KIND_IDS.include?(qualification_kind_id) && EVENT_KIND_IDS.include?(event_kind_id)
      end
    end
  end

  def change
    create_table :event_kind_qualification_kinds do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_kind, null: false
      t.string :category, null: false
      t.string :role, null: false
    end

    Updater.new(:qualification_kinds, :qualification, self).update
    Updater.new(:preconditions, :precondition, self).update
    Updater.new(:prolongations, :prolongation, self).update

    drop_table :event_kinds_qualification_kinds
    drop_table :event_kinds_prolongations
    drop_table :event_kinds_preconditions

    add_index(:event_kind_qualification_kinds, :category)
    add_index(:event_kind_qualification_kinds, :role)
  end
end

