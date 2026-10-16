class EventDescriptionAsRichText < ActiveRecord::Migration[8.0]
  def up
    event_translation_class = Class.new(ActiveRecord::Base) do
      self.table_name = "event_translations"
    end
    event_translation_class.find_each do |translation|
      description = translation.description
      PaperTrail.request(enabled: false) do
        ActionText::RichText.create!(
          name: "description",
          body: description_as_action_content(description),
          record: translation,
          record_type: "Event::Translation"
        )
      end
    end
    remove_column :event_translations, :description
  end

  def down
    add_column :event_translations, :description, :text;
    ActionText::RichText
      .where(record_type: "Event::Translation", name: "description").find_each do |action_text|
      PaperTrail.request(enabled: false) do
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

  def description_as_action_content(description)
    html_escaped_description = ERB::Util.html_escape(description)
    html_description = html_escaped_description.gsub("\n", "</br>")
    ActionText::Content.new(html_description)
  end
end
