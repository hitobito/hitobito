# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FormBuilder::TranslatedInputFieldBuilder
  private

  def translated_input_field(attr, rich_text, args = {})
    available_locales = Settings.application.languages.keys
    return(rich_text ? rich_text_area(attr, **args, already_translated: true) : input_field(attr, **args, already_translated: true)) unless Globalized.globalize_inputs?

    content_tag(:div, data: {controller: "translatable-fields", "translatable-fields-additional-languages-text-value": I18n.t("global.form.additional_languages").to_s}) do
      current_locale_input(attr, rich_text, args) + other_locale_inputs(attr, available_locales, rich_text, args) +
        help_block("", "data-translatable-fields-target": "translatedFieldsDisplay")
    end
  end

  def current_locale_input(attr, rich_text, args = {})
    with_translation_button do
      input_for_locale(attr, I18n.locale, rich_text, **args, value: @object.send(:"#{attr}_#{I18n.locale}"))
    end
  end

  def other_locale_inputs(attr, available_locales, rich_text, args = {})
    content_tag(:div, {class: "hidden", "data-translatable-fields-target": "toggle"}) do
      other_locale_inputs = available_locales.excluding(I18n.locale).map do |locale|
        input_for_locale("#{attr}_#{locale}", locale, rich_text, **args, data: {
          "translatable-fields-target": "translatedField",
          action: "input->translatable-fields#updateTranslatedFields trix-change->translatable-fields#updateTranslatedFields"
        })
      end
      safe_join(other_locale_inputs)
    end
  end

  def with_translation_button
    content_tag(:div, class: "d-flex") do
      yield +
        action_button(nil, nil, "language", {class: "mb-2", "data-action": "translatable-fields#toggleFields", type: "button", in_button_group: true})
    end
  end

  def input_for_locale(attr, locale, rich_text, args = {})
    content_tag(:div, class: "input-group me-2 mb-2") do
      locale_input = content_tag(:span, locale.to_s.upcase, class: "input-group-text") +
        (rich_text ? rich_text_area(attr, **args, already_translated: true, toolbar: "#{attr}_toolbar") : input_field(attr, **args, already_translated: true))
      rich_text ? locale_input.prepend(content_tag("trix-toolbar", nil, id: "#{attr}_toolbar")) : locale_input
    end
  end

  def translated_field?(attr, already_translated)
    @object.respond_to?(:translated_attribute_names) && !already_translated && @object.translated_attribute_names.include?(attr)
  end
end
