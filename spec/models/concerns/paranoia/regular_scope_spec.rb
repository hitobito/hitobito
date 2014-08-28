# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Paranoia::RegularScope do

  let(:kind)   { event_kinds(:slk) }
  let(:course) { Fabricate(:course, kind: kind) }
  before do
    course
    kind.events(true)
    kind.destroy # explicitly destroy kind in spec to test interaction with translations
  end

  it 'default scope returns also deleted entries' do
    Event::Kind.all.should have(4).items
  end

  it 'list returns also deleted entries' do
    Event::Kind.list.should have(4).items
  end

  it 'keeps references to deleted entries' do
    course.reload
    course.kind.should eq(kind)
  end

  it 'shows names of deleted entries' do
    course.reload
    course.kind.to_s.should eq('SLK (Scharleiterkurs)')
  end

end
