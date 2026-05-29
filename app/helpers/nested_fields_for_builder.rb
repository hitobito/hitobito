# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NestedFieldsForBuilder
  delegate :content_tag, :capture, :render, :link_to, to: :template
  delegate :fields_for, :object, :template, to: :@form

  def initialize(form)
    @form = form
  end

  def build(assoc, partial_name, record_object, options, limit, &block)
    stimulus_controller = "nested-form"
    options = options.to_h
    link_title = options.delete(:link_to_add_title) || I18n.t("global.associations.add")
    add_button = content_tag(:p,
      link_to(link_title, "javascript:void(0)", class: "text w-100 align-with-form",
        data: {action: "nested-form#add"}))
    templates = new_record_template(assoc, partial_name, stimulus_controller, options, &block)

    build_nested_form(stimulus_controller, assoc, partial_name, record_object, options, limit,
      add_button:, templates:, &block)
  end

  def build_for_event_questions(assoc, partial_name, record_object, options, limit, admin:, &block)
    stimulus_controller = "events--question-template-nested-form"
    options = options.to_h
    add_button = Dropdown::Event::QuestionAdd.new(template, @form.object.groups.first,
      @form.object, admin:).to_s
    question_template_record = object.class.reflect_on_association(assoc)&.klass&.new(admin: admin)
    templates = new_record_template(assoc, partial_name, stimulus_controller, options, &block) +
      new_record_template(assoc, "event/questions/template_fields", stimulus_controller,
        options.merge(model_object: question_template_record),
        target: "questionTemplateFormTemplate")

    build_nested_form(stimulus_controller, assoc, partial_name, record_object, options, limit,
      add_button:, templates:, &block)
  end

  private

  def build_nested_form(stimulus_controller, assoc, partial_name, record_object, options, limit,
    add_button:, templates:, &block)
    content_tag(:div, class: "nested-form",
      data: stimulus_controller_data(stimulus_controller, assoc, limit)) do
      fields_body(assoc, partial_name, record_object, stimulus_controller, &block) +
        content_tag(:div, class: "controls") do
          add_button + templates
        end
    end
  end

  def prefix(stimulus_controller)
    stimulus_controller.gsub("--", "__").tr("-", "_")
  end

  def stimulus_controller_data(stimulus_controller, assoc, limit)
    p = prefix(stimulus_controller)
    {controller: stimulus_controller, "#{p}_assoc_value": assoc, "#{p}_limit_value": limit}
  end

  def fields_body(assoc, partial_name, record_object, stimulus_controller, &block)
    p = prefix(stimulus_controller)
    content_tag(:div, id: "#{assoc}_fields") do
      fields_for(assoc, record_object) do |fields|
        content_tag(:div, class: "fields", style: ("display: none" if fields.object._destroy)) do
          (block ? capture(fields,
            &block) : render(partial_name, f: fields)) + fields.hidden_field(:_destroy)
        end
      end.to_s.html_safe + content_tag(:div, nil, data: {"#{p}_target": "target"})
    end
  end

  def new_record_template(assoc, partial_name, stimulus_controller, options, target: "template",
    &block)
    p = prefix(stimulus_controller)
    # Use a unique placeholder that includes the association name to avoid
    # collision when this template is nested inside another template
    placeholder = "NEW_#{assoc.to_s.upcase}_RECORD"
    content_tag(:template, data: {"#{p}_target": target}) do
      content_tag(:div, class: "fields", data: {new_record: true}) do
        fields_for(assoc, options[:model_object] ||
                   object.class.reflect_on_association(assoc)&.klass&.new,
          child_index: placeholder) do |fields|
          (block ? capture(fields,
            &block) : render(partial_name, f: fields)) + fields.hidden_field(:_destroy)
        end
      end
    end
  end
end
