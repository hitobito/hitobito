#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddQuestionTemplateTable < ActiveRecord::Migration[8.0]
  def up
    create_table :event_question_templates do |t|
      t.belongs_to :group, null: false
      t.belongs_to :question, null: false
      t.string :event_type
      t.boolean :default, null: false, default: false
      t.boolean :inherit, null: false, default: false
    end

    add_column :event_questions, :derived, :boolean, null: false, default: false
    add_column :event_questions, :required, :boolean, null: false, default: false
    add_reference :event_questions, :event_question_template

    execute <<-SQL
      UPDATE "event_questions" SET "required" = TRUE WHERE "disclosure" = 'required'
    SQL

    execute <<-SQL
      DELETE FROM "event_questions" WHERE "disclosure" = 'hidden' AND "event_id" IS NOT NULL;
    SQL

    execute <<-SQL
      INSERT INTO "event_question_templates" (
        "group_id",
        "question_id",
        "event_type",
        "default",
        "inherit"
      )
      SELECT
        (SELECT id FROM (SELECT "id" FROM "groups" WHERE "parent_id" IS NULL LIMIT 1)),
        "id",
        "event_type",
        CASE
          WHEN "disclosure" = 'hidden' THEN FALSE
          ELSE TRUE
        END,
        TRUE
      FROM "event_questions"
      WHERE "event_id" IS NULL;
    SQL

    execute <<-SQL
      UPDATE "event_questions"
      SET "event_question_template_id" = "event_question_templates"."id"
      FROM "event_question_templates"
      WHERE "derived_from_question_id" = "event_question_templates"."question_id"
    SQL

    remove_column :event_questions, :disclosure, :string
    remove_column :event_questions, :derived_from_question_id, :integer
    remove_column :event_questions, :event_type, :string
  end

  def down
    add_column :event_questions, :derived_from_question_id, :integer
    add_column :event_questions, :event_type, :string
    add_column :event_questions, :disclosure, :string

    remove_reference :event_questions, :event_question_template
    remove_column :event_questions, :required

    drop_table :event_question_templates
  end
end
