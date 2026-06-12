# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NestedFieldsForBuilder
  delegate :content_tag, :capture, :render, :link_to, to: :template
  delegate :fields_for, :object, :template, to: :@form

  class_attribute :stimulus_controller
  self.stimulus_controller = "nested-form"

  attr_reader :assoc, :partial_name, :record_object, :options, :limit

  def initialize(form, assoc, partial_name = nil, record_object = nil, options = nil, limit = nil)
    @form = form
    @assoc = assoc
    @partial_name = partial_name
    @record_object = record_object
    @options = options.to_h
    @limit = limit
  end

  def build(&block)
    link_title = options.delete(:link_to_add_title) || I18n.t("global.associations.add")
    add_button = content_tag(:p) do
      link_to(link_title,
        "javascript:void(0)",
        class: "text w-100 align-with-form",
        data: {action: "nested-form#add"})
    end
    templates = new_record_template(partial_name, &block)

    build_nested_form(add_button:, templates:, &block)
  end

  private

  def build_nested_form(add_button:, templates:, &block)
    content_tag(:div, class: "nested-form",
      data: stimulus_controller_data) do
      fields_body(&block) +
        content_tag(:div, class: "controls") do
          add_button + templates
        end
    end
  end

  def prefix
    stimulus_controller.gsub("--", "__").tr("-", "_")
  end

  def stimulus_controller_data
    p = prefix
    {controller: stimulus_controller, "#{p}_assoc_value": assoc, "#{p}_limit_value": limit}
  end

  def fields_body(&block)
    p = prefix
    content_tag(:div, id: "#{assoc}_fields") do
      fields_for(assoc, record_object) do |fields|
        content_tag(:div, class: "fields", style: ("display: none" if fields.object._destroy)) do
          render_block_or_partial(fields, partial_name, &block)
        end
      end.to_s.html_safe + content_tag(:div, nil, data: {"#{p}_target": "target"})
    end
  end

  def new_record_template(partial_name, model_object: nil, target: "template",
    &block)
    p = prefix
    # Use a unique placeholder that includes the association name to avoid
    # collision when this template is nested inside another template
    placeholder = "NEW_#{assoc.to_s.upcase}_RECORD"
    content_tag(:template, data: {"#{p}_target": target}) do
      content_tag(:div, class: "fields", data: {new_record: true}) do
        record = model_object || options[:model_object] ||
          object.class.reflect_on_association(assoc)&.klass&.new
        fields_for(assoc, record, child_index: placeholder) do |fields|
          render_block_or_partial(fields, partial_name, &block)
        end
      end
    end
  end

  def render_block_or_partial(fields, partial_name, &block)
    content = if block_given?
      capture(fields, &block)
    else
      render(partial_name, f: fields)
    end
    content + fields.hidden_field(:_destroy)
  end
end
