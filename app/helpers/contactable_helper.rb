#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactableHelper
  def contact_method_label_field(form)
    feature_gate_key = "#{form.object.class.name.underscore}.free_text_label"

    return contact_method_label_text_field(form) if FeatureGate.enabled?(feature_gate_key)

    contact_method_label_select(form)
  end

  def contact_method_label_text_field(form)
    form.input_field(:translated_label,
      placeholder: t(".placeholder_type"),
      data: {provide: :typeahead, source: form.object.class.available_labels})
  end

  def contact_method_label_select(form)
    contact_method = form.object
    current_label = contact_method.label
    options = (contact_method.class.predefined_labels | [current_label].compact).map do |value|
      translated = contact_method.class.translate_label(value)
      OpenStruct.new(value: value, translated: translated)
    end
    form.collection_select(:translated_label, options, :value, :translated, {},
      class: "form-select form-select-sm")
  end

  def contactable_public_field_icon
    content_tag(:span, data: {bs_toggle: :tooltip},
      title: t("contactable.public_check_box.tooltip")) do
      safe_join([
        t("activerecord.attributes.social_account.public"),
        icon(:info, class: "ms-1")
      ], " ")
    end
  end

  def info_field_set_tag(legend = nil, options = {}, &block)
    if entry.is_a?(Group)
      opts = {class: "info"}
      opts.merge!(entry.contact ? {style: "display: none"} : {})
      field_set_tag(legend, options.merge(opts), &block)
    else
      field_set_tag(legend, options, &block)
    end
  end
end
