# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NestedFieldsForBuilders
  class EventQuestion < NestedFieldsForBuilder
    def build(admin:, &block)
      stimulus_controller = "events--question-template-nested-form"
      add_button = Dropdown::Event::QuestionAdd.new(template, @form.object.groups.first,
        @form.object, admin:).to_s
      question_template_record = object.class.reflect_on_association(assoc)&.klass&.new(admin: admin)
      templates = new_record_template(partial_name, stimulus_controller, &block) +
        new_record_template("event/questions/template_fields", stimulus_controller,
          model_object: question_template_record,
          target: "questionTemplateFormTemplate")

      build_nested_form(stimulus_controller, add_button:, templates:, &block)
    end
  end
end
