# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/HelperInstanceVariable This is a helper-CLASS
module Dropdown
  module Event
    class QuestionAdd < Dropdown::Base
      attr_reader :group, :event, :admin

      def initialize(template, group, event, admin: false)
        label = I18n.t("global.associations.add")
        super(template, label)
        @main_link = "javascript:void(0)"
        @button_group_class = "btn-group dropdown align-with-form"
        @group = group
        @event = event
        @admin = admin

        init_items
      end

      private

      def label_with_link
        if main_link
          template.action_button(label, main_link, icon, in_button_group: true,
            data: {action: "events--question-template-nested-form#add"})
        end
      end

      def init_items
        ::Event::QuestionTemplate.applicable_to([group], event_type: event.type, admin:,
          default: [true, false]).find_each do |question_template|
          derived_question = question_template.derive_question
          add_item(question_template.to_s, "javascript:void(0)",
            data: {action: "events--question-template-nested-form#addFromTemplate",
                   template_attributes: derived_question.attributes
            .merge(template_id: derived_question.template_id)})
        end
      end
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable This is a helper-CLASS
