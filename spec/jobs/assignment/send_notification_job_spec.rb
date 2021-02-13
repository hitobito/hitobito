# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Assignment::SendNotificationJob do
  include ActiveJob::TestHelper

  let(:job) { Assignment::SendNotificationJob.new(assignment) }
  let(:person) { people(:bottom_member) }
  let(:attachment) { messages(:letter) }
  let(:assignment) do
    Assignment.create!(person: person,
                       creator: people(:top_leader),
                       attachment: attachment,
                       title: "Example printing assignment",
                       description: "please print this ok?")
  end

  it "sends email notification with assignment title" do
    expect do
      perform_enqueued_jobs do
        job.perform
      end
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
