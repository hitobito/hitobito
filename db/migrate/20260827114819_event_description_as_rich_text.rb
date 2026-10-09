class EventDescriptionAsRichText < ActiveRecord::Migration[8.0]
  def up
    Event::Translation.find_each do |translation|
      description = translation.description
      PaperTrail.request(enabled: false) do
        ActionText::RichText.create!(
          name: "description",
          body: ActionText::Content.new(description),
          record: translation
        )
      end
    end
    remove_column :event_translations, :description;
  end

  def down
    ActionText::RichText.reset_column_information
    ActiveRecord::Base.connection.clear_cache!
    ActionText::RichText
      .where(record_type: "Event::Translation", name: "description").find_each do |action_text|
      translation = action_text.record
      if action_text.body.present? && translation.present?
        translation.update_column(
          :description, action_text.body.to_plain_text
        )
      end
      action_text.destroy!
    end
  end
end
