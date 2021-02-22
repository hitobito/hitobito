# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Assignment::AssigneeNotificationMailer do
  let(:assignment) { assignments(:printing) }
  let(:assignee_email) { "assignee_notifications@example.com" }
  let(:mail) { Assignment::AssigneeNotificationMailer.assignee_notification(assignee_email, assignment) }

  context "assignee notification mail" do
    it "shows assignment title" do
      expect(mail.subject).to eq("Druckauftrag erhalten")
      expect(mail.body).to include(assignment.title)
    end
  end
end
