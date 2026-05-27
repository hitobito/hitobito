# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QuestionTemplatesController < SimpleCrudController
  self.nesting = Group
  self.sort_mappings = {question: "event_question_translations.question"}
  self.permitted_attrs = [
    :event_type, :default, :inherit,
    {
      question_attributes: [
        :id, :type, :admin, :question, :choices, :multiple_choices, :required, :sensitive,
        {choices_attributes: [:choice, :_destroy]}
      ]
    }
  ]

  decorates :question_templates

  helper_method :application_entries, :admin_entries, :group

  before_action :assert_template_editable, only: [:edit, :update, :destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

  def self.model_class
    Event::QuestionTemplate
  end

  private

  def build_entry
    super.tap { _1.build_question(admin: params[:admin]) }
  end

  def authorize_class
    authorize!(:index_question_templates, group)
  end

  def index_path
    group_question_templates_path(group)
  end

  def application_entries = @application_entries ||= entries.where(event_questions: {admin: false})

  def admin_entries = @admin_entries ||= entries.where(event_questions: {admin: true})

  def list_entries
    @list_entries ||= super.joins(:question)
      .merge(Event::Question.list)
      .includes(question: :translations)
      .select(Event::QuestionTemplate.attribute_names)
  end

  def group = @group ||= Group.find(params[:group_id])

  def assert_template_editable
    raise CanCan::AccessDenied unless entry.question.class.template_editable
  end
end
