#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Examples::TerminatableJobWithCallback do
  it "should execute custom logic before test is terminated" do
    terminatable_job = described_class.new
    expect do
      terminatable_job = terminatable_job.enqueue!
    end.to change(Delayed::Job, :count).by(1)

    expect do
      Thread.new do
        sleep 3
        terminatable_job.status_control = "terminate"
        terminatable_job.save!
      end
      worker = Delayed::Worker.new
      worker.max_run_time = 10.seconds
      worker.work_off
    end.to change(Delayed::Job, :count).by(-1)

    expect(Person.first.name).to eql("changed after job termination")
  end
end
