class EventDescriptionAsRichText < ActiveRecord::Migration[8.0]
  def up
    Event::Translation.find_each do |translation|
      description = translation.description

      ActionText::RichText.create!(
        name: "description",
        body: ActionText::Content.new(description),
        record: translation
      )
    end
  end

  def down
    begin
      ActionText::RichText
        .where(record_type: "Event::Translation", name: "description").find_each do |action_text|
        translation = action_text.record
        translation.update_column(
          :description, action_text.body.to_plain_text
      ) unless action_text.body.nil?
        action_text.destroy!
      end
    rescue StandardError => e
      # ToDo
    end
  end
end
