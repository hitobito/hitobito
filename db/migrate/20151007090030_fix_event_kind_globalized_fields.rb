# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FixEventKindGlobalizedFields < ActiveRecord::Migration[4.2]
  def up
    Event::Kind.add_translation_fields!({ general_information: :text }, migrate_data: true)
    remove_column :event_kinds, :general_information

    Event::Kind.add_translation_fields!({ application_conditions: :text }, migrate_data: true)
    remove_column :event_kinds, :application_conditions
  end

  def down
    fail 'translation data will be lost!'

    add_column(:event_kinds, :general_information, :text)
    add_column(:event_kinds, :application_conditions, :text)

    remove_column :event_kind_translations, :general_information
    remove_column :event_kind_translations, :application_conditions
  end
end
