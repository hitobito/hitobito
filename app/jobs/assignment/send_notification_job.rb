# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Assignment::SendNotificationJob < BaseJob
  self.parameters = [:assignment_id, :locale]

  def initialize(assignment)
    super()
    @assignment_id = assignment.id
  end

  def perform
    set_locale
    Assignment::AssigneeNotificationMailer.assignee_notification(assignee_email,
      assignment).deliver_now
  end

  def assignment
    @assignment ||= Assignment.find(@assignment_id)
  end

  def assignee_email
    assignment.person.email
  end
end
