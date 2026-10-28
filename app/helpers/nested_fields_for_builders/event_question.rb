# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NestedFieldsForBuilders
  class EventQuestion < NestedFieldsForBuilder
    self.stimulus_controller = "events--question-template-nested-form"

    def build(admin:, &block)
      add_button = Dropdown::Event::QuestionAdd.new(template, @form.object.groups.first,
        @form.object, admin:).to_s
      templates = new_record_template(partial_name, model_object: new_question(admin:), &block) +
        new_record_template("event/questions/template_fields",
          model_object: new_question(admin:),
          target: "questionTemplateFormTemplate")

      build_nested_form(add_button:, templates:, &block)
    end

    private

    def new_question(admin:)
      object.class.reflect_on_association(assoc)&.klass&.new(admin:)
    end
  end
end
