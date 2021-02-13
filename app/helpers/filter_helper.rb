# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterHelper

  # rubocop:disable Rails/OutputSafety
  def direct_filter(attr, label = nil, &block)
    html = "".html_safe
    label ||= model_class.human_attribute_name(attr)
    html += label_tag(attr, label, class: "control-label").html_safe if label
    html += capture(&block)
    content_tag(:div, html, class: "control-group").html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def direct_filter_select(attr, list, label = nil, options = {})
    options.reverse_merge!(prompt: t("global.all"), value_method: :first, text_method: :second)
    add_css_class(options, "control-group")
    options[:data] ||= {}
    options[:data][:submit] = true
    select_options = options_from_collection_for_select(list,
                                                        options.delete(:value_method),
                                                        options.delete(:text_method),
                                                        params[attr])
    direct_filter(attr, label) { select_tag(attr, select_options, options) }
  end
end
