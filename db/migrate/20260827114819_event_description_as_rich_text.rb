class EventDescriptionAsRichText < ActiveRecord::Migration[8.0]
  def up
    Event::Translation.all.each do |translation|
      translation.description = CustomContent.create!(
        locale: translation.locale,
        label: translation.description,
        custom_content: translation,
      )
      translation.save!
    end
  end

  # def down
  #   ActionText::RichText.where(record_type: Event::Translations) do |actionText|
  #     translation = actionText.record
  #     translation.description = actionText.label.to_plain_text
  #     translation.save!
  #     actionText.destroy!
  #   end
  # end
end
