# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FormBuilder::TranslatedInputFieldBuilder
  private

  def translated_input_field(attr, rich_text, args = {})
    return (rich_text ? rich_text_area(attr, **args, already_translated: true) : input_field(attr, **args, already_translated: true)) unless Globalized.globalize_inputs?

    content_tag(:div, data: {controller: "translatable-fields", "translatable-fields-additional-languages-text-value": I18n.t("global.form.additional_languages").to_s}) do
      current_locale_input(attr, rich_text, args) +
        other_locale_inputs(attr, rich_text, args) +
        help_block("", "data-translatable-fields-target": "translatedFieldsDisplay")
    end
  end

  def current_locale_input(attr, rich_text, args = {})
    content_tag(:div, class: "d-flex") do
      input_for_locale(attr, I18n.locale, rich_text, **args, value: @object.send(:"#{attr}_#{I18n.locale}")) do
        action_button(nil, nil, "language",
          {"data-action": "translatable-fields#toggleFields", type: "button", in_button_group: true, "data-bs-toggle": "tooltip", "data-bs-title": I18n.t("global.form.input_translation_button")})
      end
    end
  end

  def other_locale_inputs(attr, rich_text, args = {})
    content_tag(:div, {class: "hidden", "data-translatable-fields-target": "toggle"}) do
      other_locale_inputs = Settings.application.languages.keys.excluding(I18n.locale).map do |locale|
        input_for_locale("#{attr}_#{locale}", locale, rich_text, **args, data: {
          "translatable-fields-target": "translatedField",
          action: "input->translatable-fields#updateTranslatedFields trix-change->translatable-fields#updateTranslatedFields"
        }, value: @object.send(:"#{attr}_#{locale}"))
      end
      safe_join(other_locale_inputs)
    end
  end

  def input_for_locale(attr, locale, rich_text, args = {})
    content_tag(:div, class: "input-group mb-2") do
      locale_input = locale_indicator(locale) +
        (rich_text ? rich_text_area(attr, **args, already_translated: true, toolbar: "#{attr}_toolbar") : input_field(attr, **args, already_translated: true))
      locale_input.prepend(content_tag("trix-toolbar", nil, id: "#{attr}_toolbar")) if rich_text
      block_given? ? locale_input + yield : locale_input
    end
  end

  def locale_indicator(locale)
    content_tag(
      :span, locale.to_s.upcase,
      class: "input-group-text d-flex justify-content-center rounded-start", "data-translatable-fields-target": "localeIndicator",
      "data-bs-toggle": "tooltip", "data-bs-title": I18n.t("global.form.locale_indicator")
    )
  end

  def translated_field?(attr, already_translated)
    @object.respond_to?(:translated_attribute_names) && !already_translated && @object.translated_attribute_names.include?(attr)
  end
end
