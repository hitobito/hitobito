# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Helper methods included in the standard form builder used to
# create globalized input fields, which allow the user to
# fill in an input for a globalized attribute in all available languages. The
# already_globalized argument is passed to the input field, which tells
# the standard form builder to render the actual input field instead of calling
# the helpers in here again.
module Globalized::GlobalizedInputFieldHelpers
  private

  def globalized_input_field(attr, args = {})
    unless Globalized.globalize_inputs?
      return input_field(attr, **args, already_globalized: true)
    end

    globalized_inputs(attr, false, args)
  end

  def globalized_rich_text_area(attr, args = {})
    unless Globalized.globalize_inputs?
      return rich_text_area(attr, **args, already_globalized: true)
    end

    globalized_inputs(attr, true, args)
  end

  def globalized_inputs(attr, rich_text, args = {})
    content_tag(:div, data: {
      controller: "globalized-fields",
      "globalized-fields-additional-languages-text-value":
        I18n.t("global.form.additional_languages").to_s
    }) do
      current_locale_input(attr, rich_text, args) +
        other_locale_inputs(attr, rich_text, args) +
        help_block("", "data-globalized-fields-target": "globalizedFieldsDisplay")
    end
  end

  def current_locale_input(attr, rich_text, args = {})
    content_tag(:div, class: "d-flex") do
      input_for_locale(
        attr, I18n.locale, rich_text, **args,
        value: @object.send(:"#{attr}_#{I18n.locale}")
      ) do
        action_button(nil, nil, "language", {
          "data-action": "globalized-fields#toggleFields",
          type: "button",
          in_button_group: true,
          "data-bs-toggle": "tooltip",
          "data-bs-title": I18n.t("global.form.input_translation_button")
        })
      end
    end
  end

  def other_locale_inputs(attr, rich_text, args = {})
    content_tag(:div, {class: "hidden", "data-globalized-fields-target": "toggle"}) do
      other_locale_inputs = Globalized.additional_languages.map do |locale|
        input_for_locale("#{attr}_#{locale}", locale, rich_text, **args, data: {
          "globalized-fields-target": "globalizedField",
          action: "input->globalized-fields#updateGlobalizedFieldsDisplay" \
            " trix-change->globalized-fields#updateGlobalizedFieldsDisplay"
        }, value: @object.send(:"#{attr}_#{locale}"))
      end
      safe_join(other_locale_inputs)
    end
  end

  def input_for_locale(attr, locale, rich_text, args = {})
    content_tag(:div, class: "input-group input-group-sm #{"mt-2" unless locale == I18n.locale}") do
      locale_input = if rich_text
        rich_text_area_for_locale(attr, locale, args)
      else
        input_field_for_locale(attr, locale, args)
      end
      block_given? ? locale_input + yield : locale_input
    end
  end

  def rich_text_area_for_locale(attr, locale, args = {})
    content_tag("trix-toolbar", nil, id: "#{attr}_toolbar") +
      locale_indicator(locale) +
      rich_text_area(attr, **args, already_globalized: true, toolbar: "#{attr}_toolbar")
  end

  def input_field_for_locale(attr, locale, args = {})
    locale_indicator(locale) +
      input_field(attr, **args, already_globalized: true)
  end

  def locale_indicator(locale)
    content_tag(
      :span, locale.to_s.upcase,
      class: "input-group-text d-flex justify-content-center locale-indicator bg-transparent",
      "data-globalized-fields-target": "localeIndicator",
      "data-bs-toggle": "tooltip", "data-bs-title": I18n.t("global.form.locale_indicator")
    )
  end

  def globalized_field?(attr, already_globalized)
    @object.respond_to?(:translated_attribute_names) &&
      !already_globalized && @object.translated_attribute_names.include?(attr.to_sym)
  end
end
