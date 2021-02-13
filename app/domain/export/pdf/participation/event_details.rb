# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class EventDetails < Section
    attr_reader :count

    def render
      render_description if description?
      render_requirements if requirements?
    end

    private

    def description?
      event.description.present?
    end

    def render_description
      with_header(description_title) do
        text strip_tags(event.description)
      end
    end

    def render_requirements # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      with_header(I18n.t("event.participations.print.requirements_for_#{i18n_event_postfix}")) do
        if event.application_conditions?
          text strip_tags(event.application_conditions)
          move_down_line
        end

        if event_with_kind? && event.kind.application_conditions.present?
          text event.kind.application_conditions
          move_down_line
        end

        if course?
          boxed_attr(human_attribute_name(:minimum_age, event_kind)) do
            translated_minimum_age
          end
          boxed_attr(human_attribute_name(:preconditions, event_kind)) do
            precondition_qualifications_summary
          end
        end
      end
    end

    def translated_minimum_age
      I18n.t("qualifications.in_years", years: event_kind.minimum_age) if event_kind.minimum_age
    end

    def precondition_qualifications_summary
      kinds = event_kind.qualification_kinds("precondition", "participant").group_by(&:id)
      grouped_ids = event_kind.grouped_qualification_kind_ids("precondition", "participant")
      sentences = grouped_ids.collect { |ids|
        ids.collect { |id| kinds[id].first.to_s }.sort.to_sentence
      }
      sentences.join(" " + I18n.t("event.kinds.qualifications.or").upcase + " ")
    end

    def description_title
      human_attribute_name(:description, event)
    end

    def course?
      event.class == Event::Course
    end

    def event_kind
      (event_with_kind? && event.kind) || NullEventKind.new
    end

    def requirements?
      [event.application_conditions,
       event_kind.minimum_age,
       event_kind.qualification_kinds("precondition", "participant"),].any?(&:present?)
    end

    def boxed_attr(title)
      text = yield
      if text.present?
        render_columns(-> { text title }, -> { text text })
      end
    end

    class NullEventKind < OpenStruct
      def qualification_kinds(*)
        []
      end
    end
  end
end
