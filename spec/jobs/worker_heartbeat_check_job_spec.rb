#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe WorkerHeartbeatCheckJob do
  subject { WorkerHeartbeatCheckJob.new }

  it "relays mails and gets rescheduled" do
    expect(Delayed::Heartbeat).to receive(
      :delete_workers_with_different_version
    )
    expect(Delayed::Heartbeat).to receive(:delete_timed_out_workers)
    subject.perform
  end
end
