class AddPlainTextBodyToRichText < ActiveRecord::Migration[8.0]
  def change
    add_column(:action_text_rich_texts, :plain_text_body, :text)
    ActionText::RichText.find_each do |rich_text|
      next unless rich_text.body.present?

      rich_text.update(plain_text_body: rich_text.body.to_plain_text)
    end
  end
end
