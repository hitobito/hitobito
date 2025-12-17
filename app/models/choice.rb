#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Choice
  include ActiveModel::Model

  def initialize(choice_translations = {})
    @choice_translations = choice_translations
  end

  attr_accessor :choice_translations

  def id
  end

  def choice
    choice_with_fallbacks
  end

  Globalized.languages.each do |lang|
    define_method(:"choice_#{lang}") { @choice_translations[lang] }
  end

  def to_s
    choice
  end

  def translated_attribute_names
    [:choice]
  end

  def self.translated_attribute_names
    [:choice]
  end

  def _destroy
  end

  # Event question answers are saved by the actual value(s) of the selected choice(s).
  # If the question is multiple choice the values of the choices are saved as comma
  # separated string in the answer.
  # To know if a choice is selected when rendering the radiobuttons/checkboxes we
  # check if any of the answers is included in the translations of the choice.
  # This ensures that the choice is still selected when changing the locale of the client.
  def checked?(answer)
    answer.to_s.split(",").map(&:strip).any? { |a| choice_translations.value?(a) }
  end

  private

  def choice_with_fallbacks(fallbacks = I18n.fallbacks)
    case fallbacks
    when true
      choice_with_fallback(I18n.default_locale)
    when Symbol, String
      choice_with_fallback(fallbacks.to_sym)
    when Array
      fallback_from_array(fallbacks)
    when Hash
      choice_with_fallbacks(fallbacks[I18n.locale])
    else
      @choice_translations[I18n.locale]
    end
  end

  def fallback_from_array(fallbacks)
    fallbacks.map { |fallback| @choice_translations[fallback] }.find(&:present?) ||
      @choice_translations[I18n.locale]
  end

  def choice_with_fallback(fallback)
    current_choice = @choice_translations[I18n.locale]
    fallback_choice = @choice_translations[fallback]

    if current_choice.present? || (current_choice.blank? && fallback_choice.blank?)
      return current_choice
    end

    fallback_choice
  end
end
