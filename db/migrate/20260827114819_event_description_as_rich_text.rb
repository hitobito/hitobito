class EventDescriptionAsRichText < ActiveRecord::Migration[8.0]
  def up
    ActionText::RichText.reset_column_information
    event_translation_class = Class.new(ActiveRecord::Base) do
      self.table_name = "event_translations"
    end
    event_translation_class.where.not(description: nil).in_batches do |batch|
      rich_texts = batch.pluck(:id, :description).filter_map do |id, description|
        rich_text_attributes(id, description)
      end
      ActionText::RichText.insert_all(rich_texts) if rich_texts.any?
    end
    remove_column :event_translations, :description
  end

  def down
    add_column :event_translations, :description, :text
    execute(<<~SQL)
      UPDATE event_translations
      SET description = action_text_rich_texts.plain_text_body
      FROM action_text_rich_texts
      WHERE action_text_rich_texts.record_type = 'Event::Translation'
        AND action_text_rich_texts.name = 'description'
        AND action_text_rich_texts.record_id = event_translations.id
    SQL
    execute(<<~SQL)
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'Event::Translation' AND name = 'description'
    SQL
  end

  private

  def rich_text_attributes(translation_id, description)
    return if description.blank?

    content = ActionText::Content.new(description_as_html(description))
    {
      record_type: "Event::Translation",
      record_id: translation_id,
      name: "description",
      body: content,
      plain_text_body: content.to_plain_text
    }
  end

  def description_as_html(description)
    lines = description.strip.split(/\r?\n/).map { |line| ERB::Util.html_escape(line) }
    "<div>#{lines.join("<br>")}</div>"
  end
end
