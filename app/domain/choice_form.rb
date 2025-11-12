module ChoiceForm
  class Form
    def choices(question)
      languages = [I18n.locale] + Globalized.additional_languages
      globalized_grouped_choice_items = languages.map do |lang|
        I18n.with_locale(lang) do
          question.choice_items
        end
      end.transpose

      globalized_grouped_choice_items.map { |choice_translations| Choice.new(choice_translations) }
    end
  end

  class Choice
    include ActiveModel::Model

    def initialize(choice_translations)
      define_singleton_method(:choice) { choice_translations.first }

      languages = [I18n.locale] + Globalized.additional_languages
      languages.each do |lang|
        define_singleton_method(:"choice_#{lang}") { choice_translations.shift }
      end
    end

    def id
    end

    def to_s
      @choice
    end

    def translated_attribute_names
      [:choice]
    end
  end
end
