# encoding: utf-8

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::ExportBaseJob do

  class MyJob < described_class
    self.parameters = PARAMETERS
  end

  let(:subject) { MyJob.new(:csv, people(:top_leader).id) }

  it "sets locale when reading job from database" do
    allow(I18n).to receive(:locale).and_return(:fr)
    subject.enqueue!
    expect(subject.instance_variable_get("@locale")).to eq "fr"

    job = subject.delayed_jobs.last.payload_object
    expect(job.instance_variable_get("@locale")).to eq "fr"
  end

end
