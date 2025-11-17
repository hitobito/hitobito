module ChoiceForm
  class Choice
    include ActiveModel::Model

    def initialize(choice_translations = {})
      define_singleton_method(:choice) { choice_translations[I18n.locale] }
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
