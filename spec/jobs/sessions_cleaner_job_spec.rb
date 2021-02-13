# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SessionsCleanerJob do
  it "clears out outdated sessesion" do
    outdated = Session.create!(session_id: :outdated, updated_at: 40.days.ago)
    current = Session.create!(session_id: :current, updated_at: 20.days.ago)

    expect do
      subject.perform
    end.to change { Session.count }.by(-1)

    expect { outdated.reload }.to raise_error ActiveRecord::RecordNotFound
    expect { current.reload }.not_to raise_error ActiveRecord::RecordNotFound
  end
end
