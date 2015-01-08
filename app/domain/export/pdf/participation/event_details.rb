# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class EventDetails < Section
    attr_reader :count

    def render
      pdf.start_new_page if description? || requirements?

      render_description if description?
      render_requirements if requirements?
    end

    private

    def description?
      event.description.present?
    end

    def render_description
      with_count(description_title) do
        text event.description
      end
    end

    def render_requirements
      with_count(I18n.t("event.participations.print.requirements_for_#{i18n_event_postfix}")) do
        boxed_attr(event, :application_conditions)

        if course?
          boxed_attr(event_kind, :minimum_age) { translated_minimum_age }
          boxed_attr(event_kind, :qualification_kinds,
                     human_attribute_name(:preconditions, event_kind),
                     %w(precondition participant))
        end
      end
    end

    def translated_minimum_age
      I18n.t('qualifications.in_years', years: event_kind.minimum_age)
    end

    def with_count(content)
      @count ||= 0
      heading { text "#{@count += 1}.", content, style: :bold }
      move_down_line
      yield
      2.times { move_down_line }
    end

    def description_title
      [human_event_name,
       human_attribute_name(:description, event).downcase].join
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
       event_kind.qualification_kinds('precondition', 'participant')].any?(&:present?)
    end

    def boxed_attr(model, attr, title = nil, args = nil)
      title ||= human_attribute_name(attr, model)

      values = Array(model.send(attr, *args)).reject(&:blank?)
      values_text = block_given? ? yield : values.map(&:to_s).join("\n")

      if values.present?
        render_boxed(-> { text title }, -> { text values_text })
      end
      move_down_line
    end

    class NullEventKind < OpenStruct
      def qualification_kinds(*)
        []
      end
    end
  end

end
