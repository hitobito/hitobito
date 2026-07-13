# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The questions of an event that a given viewer may see the answers of, filtered and in
# list order, consistent wherever questions or answers are shown or exported.
class Event::Question::VisibleList
  attr_reader :event, :ability, :participation

  def initialize(event:, ability:, participation: nil, cache: {})
    @event = event
    @ability = ability
    @participation = participation
    @cache = cache
  end

  def questions
    @questions ||= ordered_questions.select { |question| visible?(question) }
  end

  def answers(scope)
    by_question_id = scope.index_by(&:question_id)
    questions.filter_map do |question|
      by_question_id[question.id]&.tap { |answer| answer.question = question }
    end
  end

  private

  def own_participation?
    participation && ability.user_context.user == participation.person
  end

  def visible?(question)
    (own_participation? && !question.admin?) ||
      question.visible_to?(role_types, full_access: full_access?)
  end

  def ordered_questions
    @cache[[:ordered_questions, event.id]] ||= Event::Question.list.where(event:)
      .includes(:translations, :question_visibilities).to_a
  end

  def role_types
    @cache[[:role_types, event.id, ability.user_context.user.id]] ||=
      ability.user_context.user.event_role_types_for(event)
  end

  def full_access?
    return @full_access if defined?(@full_access)

    @full_access = if participation
      ability.can?(:show_full, participation)
    else
      ability.can?(:index_full_participations, event)
    end
  end
end
