module ChoiceForm
  class Choice
    include ActiveModel::Model

    def initialize(choice_translations = {})
      define_singleton_method(:choice) do
        choice_with_fallbacks(choice_translations)
      end
      Globalized.languages.each do |lang|
        define_singleton_method(:"choice_#{lang}") { choice_translations[lang] }
      end
    end

    def _destroy
    end

    def id
    end

    def to_s
      @choice
    end

    def translated_attribute_names
      [:choice]
    end

    def self.translated_attribute_names
      [:choice]
    end

    private

    def choice_with_fallbacks(choice_translations, fallbacks = I18n.fallbacks)
      case fallbacks
      when true
        choice_with_fallback(choice_translations, I18n.default_locale)
      when Symbol || String
        choice_with_fallback(choice_translations, fallbacks.to_sym)
      when Array
        fallback_from_array(choice_translations, fallbacks)
      when Hash
        choice_with_fallbacks(choice_translations, fallbacks[I18n.locale])
      else
        choice_translations[I18n.locale]
      end
    end

    def fallback_from_array(choice_translations, fallbacks)
      fallbacks.map { |fallback| choice_translations[fallback] }.find(&:present?) ||
        choice_translations[I18n.locale]
    end

    def choice_with_fallback(choice_translations, fallback)
      current_choice = choice_translations[I18n.locale]
      fallback_choice = choice_translations[fallback]

      if current_choice.present? || (current_choice.blank? && fallback_choice.blank?)
        return current_choice
      end

      fallback_choice
    end
  end

  class ChoiceReflection
    def name
      :choices
    end

    def klass
      Choice
    end
  end
end
