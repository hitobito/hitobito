#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterHelper
  # rubocop:disable Rails/OutputSafety
  def direct_filter(attr, label = nil, options = {}, &block)
    html = "".html_safe
    label ||= model_class.human_attribute_name(attr)
    html += label_tag(attr, label, class: "control-label").html_safe if label
    html += content_tag(:div, capture(&block), class: "input-group mt-2")
    content_tag(:div, html, class: "control-group row").html_safe
  end

  # rubocop:enable Rails/OutputSafety
  def direct_filter_search
    label = t("global.button.search")
    direct_filter(:q, label, class: "has-feedback has-clear") do
      search_field_tag(:q, params[:q], class: "form-control form-control-sm", placeholder: label,
        data: {submit: true}) +
        content_tag(:span, icon(:times, class: "fa-xs"), class: "input-group-text fw-bold",
          data: {clear: true})
    end
  end

  def direct_filter_select(attr, list, label = nil, options = {})
    options.reverse_merge!(prompt: t("global.all"), value_method: :first, text_method: :second)
    add_css_class(options, "form-select form-select-sm")
    options[:data] ||= {}
    options[:data][:submit] = true
    select_options = options_from_collection_for_select(list,
      options.delete(:value_method),
      options.delete(:text_method),
      params[attr])
    direct_filter(attr, label) { select_tag(attr, select_options, options) }
  end

  def direct_filter_date(attr, label = nil, options = {})
    options[:class] ||= "col-2 date form-control form-control-sm"
    direct_filter(attr, label) do
      content_tag(:div, class: "input-group") do
        content_tag(:span, icon(:"calendar-alt"), class: "input-group-text") +
          text_field(nil, attr, options)
      end
    end
  end

  def direct_filter_time(attr, label = nil, **options)
    options[:class] ||= "col-2 time form-control form-control-sm"
    direct_filter(attr, label) do
      time_field(nil, attr, options)
    end
  end

  def set_filter(filter_params = {})
    anchor = filter_params.delete :anchor
    params.to_unsafe_h.deep_merge(filter: filter_params, anchor: anchor)
  end

  def direct_filter_date_field(attr, options = {})
    options[:class] ||= "date form-control form-control-sm w-50"
    options[:value] ||= params[attr]
    options[:data] = {submit: true}
    content_tag(:span, icon(:"calendar-alt"),
      class: "input-group-text") + text_field(nil, attr, options)
  end

  def direct_filter_time_field(attr, options = {})
    options[:class] ||= "time form-control form-control-sm w-25"
    options[:value] ||= params[attr]
    options[:data] = {submit: true}
    time_field(nil, attr, options)
  end

  def direct_filter_input(options = {})
    add_css_class(options, "input-group mt-2")
    content_tag(:div, options) do
      yield
    end
  end
end
