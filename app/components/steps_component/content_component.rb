# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class StepsComponent::ContentComponent < StepsComponent::IteratingComponent
  with_collection_parameter :partial

  public :stimulus_action

  def initialize(partial:, partial_iteration:, step:, form:)
    super(iterator: partial_iteration, step: step)
    @form = form
    @partial = partial.to_s
  end

  def form_error_messages
    @form.error_messages
  end

  def model
    @form.object.step_at(index)
  end

  def call
    content_tag(:div, markup,
      class: %W[step-content #{@partial.dasherize} #{active_class}],
      data: stimulus_target("stepContent"))
  end

  def fields_for(buttons: true, &)
    partial_name = @partial.split("/").last
    content = @form.fields_for(partial_name, model) do |form|
      form.error_messages
    end
    content += @form.fields_for(partial_name, model, &)
    content += bottom_toolbar if buttons
    content
  end

  def nested_fields_for(assoc, object, &)
    fields_for(buttons: false) do |f|
      f.nested_fields_for(assoc, nil, nil, model_object: object, &)
    end
  end

  def bottom_toolbar
    content_tag(:div, build_buttons, class: "btn-toolbar allign-with-form")
  end

  def next_button(title = nil, options = {})
    type = "submit"
    title ||= I18n.t("#{@partial.tr("/", ".")}.next_button", default: nil)
    title ||= if last?
      t("groups.self_registration.form.submit")
    else
      t("steps_component.next_link")
    end
    submit_button(title, type, next_submit_button_options.merge(options))
  end

  def render?
    index <= @step
  end

  def back_link
    data = {action: stimulus_action(:back), index: index - 1}
    link_to(t("global.button.back"), "#", class: "link cancel mt-2 pt-1", data: data)
  end

  private

  def markup
    render(@partial, f: @form, c: self, required: false)
  end

  def next_submit_button_options
    options = past? ? {formnovalidate: true} : {}
    options.merge(name: :next, value: index + 1)
  end

  def build_buttons
    buttons = [next_button]
    buttons << back_link if index.positive?
    buttons << cancel_link_back_to_person if index.zero?
    safe_join(buttons)
  end

  def submit_button(label, type, options)
    content_tag(:div, class: "btn-group") do
      helpers.add_css_class(options, "btn btn-sm btn-primary mt-2")
      @form.button(label, options.merge(type: type, data: {disable_with: label}))
    end
  end

  def cancel_link_back_to_person
    if @form.object.try(:person).try(:persisted?)
      link_to(t("global.button.cancel"), person_path(@form.object.person), class: "link cancel mt-2 pt-1")
    end
  end

  def past?
    index < @form.object.current_step
  end
end
