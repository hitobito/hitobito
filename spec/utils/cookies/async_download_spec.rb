#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Cookies::AsyncDownload do
  let(:cookie_jar) { ActionDispatch::Request.new({}).cookie_jar }
  let(:value)      { JSON.parse(cookie_jar[:async_downloads]) }
  let(:subject)    { described_class.new(cookie_jar) }

  it 'tracks single download in cookie' do
    subject.set(name: 'my-file', type: 'txt')
    expect(value).to have(1).item
    expect(value.first['name']).to eq 'my-file'
    expect(value.first['type']).to eq 'txt'
  end

  it 'tracks multiple downloads in cookie' do
    subject.set(name: 'my-file', type: 'txt')
    subject.set(name: 'other-file', type: 'txt')
    expect(value).to have(2).items
  end

  it 'removes download from values' do
    subject.set(name: 'my-file', type: 'txt')
    subject.set(name: 'other-file', type: 'txt')
    subject.remove(name: 'my-file', type: 'txt')
    expect(value).to have(1).items
    expect(value.first['name']).to eq 'other-file'
  end

  it 'removes cookie if no values are left' do
    subject.set(name: 'my-file', type: 'txt')
    subject.remove(name: 'my-file', type: 'txt')
    expect(cookie_jar).not_to have_key(:async_downloads)
  end

  it 'removes properly when object is instantiated multiple times' do
    described_class.new(cookie_jar).set(name: 'my-file', type: 'txt')
    described_class.new(cookie_jar).remove(name: 'my-file', type: 'txt')
    expect(cookie_jar).not_to have_key(:async_downloads)
  end

end
