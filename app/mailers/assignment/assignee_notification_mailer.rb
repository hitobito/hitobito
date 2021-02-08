# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Assignment::AssigneeNotificationMailer < ApplicationMailer

  CONTENT_ASSIGNMENT_ASSIGNEE_NOTIFICATION = 'assignment_assignee_notification'.freeze

  def assignee_notification(assignee_email, assignment)
    @assignment = assignment

    compose(assignee_email, CONTENT_ASSIGNMENT_ASSIGNEE_NOTIFICATION)
  end

  private

  def placeholder_assignment_title
    @assignment.title
  end
end
