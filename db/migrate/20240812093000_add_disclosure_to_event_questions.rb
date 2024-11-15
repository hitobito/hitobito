class AddDisclosureToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column(:event_questions, :disclosure, :string, null: true)

    reversible do |direction|
      direction.up do
        Event::Question.where(disclosure: nil).update_all(disclosure: :optional)
        Event::Question.where(required: true).update_all(disclosure: :required)

        # validates_by_schema has already defined a validation on the column 'required' which we
        # will drop on the last line of this migration. We have to remove the validation here,
        # otherwise the seeds will fail when run in the same process as the migration.
        Event::Question._validators.delete(:required)
        Event::Question._validate_callbacks.each do |callback|
          if callback.raw_filter.try(:attributes)&.include?("required")
            Event::Question._validate_callbacks.delete(callback)
          end
        end
      end
      direction.down do
        Event::Question.where(disclosure: :optional).update_all(required: false)
        Event::Question.where(disclosure: :required).update_all(required: true)
      end
    end

    remove_column(:event_questions, :required, :boolean, default: false)
  end
end
