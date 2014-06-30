require 'spec_helper'

describe Paranoia::RegularScope do

  let(:kind)   { event_kinds(:slk) }
  let(:course) { Fabricate(:course, kind: kind) }
  before do
    course
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
