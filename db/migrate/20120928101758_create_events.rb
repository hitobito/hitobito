# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      # Allgemein
      t.belongs_to :group, null: false
      t.string :type, null: false
      t.string :name, null: false
      t.string :number
      t.string :motto
      t.string :cost
      t.integer :maximum_participants
      t.belongs_to :contact
      t.text :description
      t.text :location
      t.date :application_opening_at
      t.date :application_closing_at
      t.text :application_conditions

      # Kurse
      t.belongs_to :kind
      t.string :state, limit: 60
      t.boolean :priorization, null: false, default: false
      t.boolean :requires_approval, null: false, default: false

      t.timestamps
    end

    create_table :event_dates do |t|
      t.belongs_to :event, null: false
      t.string :label
      t.datetime :start_at
      t.datetime :finish_at
    end

    create_table :event_kinds do |t|
      t.string :label, null: false
      t.string :short_name
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :event_questions do |t|
      t.belongs_to :event #optional
      t.string :question
      t.string :choices
    end

    create_table :event_answers do |t|
      t.belongs_to :participation, null: false
      t.belongs_to :question, null: false
      t.string :answer
    end

    create_table :event_participations do |t|
      t.belongs_to :event # may be nil if application is pending
      t.belongs_to :person, null: false
      t.string :type, null: false
      t.string :label
      t.text :additional_information

      t.timestamps
    end

    create_table :event_applications do |t|
      t.belongs_to :participation, null: false
      t.belongs_to :priority_1, null: false
      t.belongs_to :priority_2
      t.belongs_to :priority_3
      t.boolean :approved, null: false, default: false
      t.boolean :rejected, null: false, default: false
      t.boolean :waiting_list, null: false, default: false
    end

  end
end
