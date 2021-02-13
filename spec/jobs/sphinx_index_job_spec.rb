# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SphinxIndexJob do
  subject { SphinxIndexJob.new }

  it "disables job if sphinx running on external host" do
    SphinxIndexJob.new.schedule
    expect(Hitobito::Application).to receive(:sphinx_local?).twice.and_return(false)
    expect do
      subject.perform
    end.to change { Delayed::Job.count }.by(-1)
  end
end
