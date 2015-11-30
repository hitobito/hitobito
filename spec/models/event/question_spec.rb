# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Question do

  let(:event) { events(:top_course) }

  it 'adds answer to participation after create' do
    expect do
      event.questions.create!(question: 'Test?', required: true)
    end.to change { Event::Answer.count }.by(1)
  end
  
end
