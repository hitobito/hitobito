# encoding: utf-8

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockWarningJob do
  subject(:job) { described_class.new }

  context '#perform' do
    it 'calls Person::BlockService.warn_within_scope!' do
      expect(Person::BlockService).to receive(:warn_within_scope!)
      job.perform
    end
  end
end
