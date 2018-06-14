require 'spec_helper'

describe AsyncDownloadCookie do
  include ActiveSupport::Testing::TimeHelpers

  let(:cookie_jar) { ActionDispatch::Request.new({}).cookie_jar }
  let(:value)      { JSON.parse(cookie_jar[:async_downloads]) }
  let(:subject)    { described_class.new(cookie_jar) }

  it 'tracks single download in cookie' do
    subject.set('my-file', 'txt')
    expect(value).to have(1).item
    expect(value.first['name']).to eq 'my-file'
    expect(value.first['type']).to eq 'txt'
  end

  it 'tracks multiple downloads in cookie' do
    subject.set('my-file', 'txt')
    subject.set('other-file', 'txt')
    expect(value).to have(2).items
  end

  it 'removes download from values' do
    subject.set('my-file', 'txt')
    subject.set('other-file', 'txt')
    subject.remove('my-file', 'txt')
    expect(value).to have(1).items
    expect(value.first['name']).to eq 'other-file'
  end

  it 'removes cookie if no values are left' do
    subject.set('my-file', 'txt')
    subject.remove('my-file', 'txt')
    expect(cookie_jar).not_to have_key(:async_downloads)
  end

  it 'removes properly when object is instantiated multiple times' do
    described_class.new(cookie_jar).set('my-file', 'txt')
    described_class.new(cookie_jar).remove('my-file', 'txt')
    expect(cookie_jar).not_to have_key(:async_downloads)
  end

  context 'Set-Cookie' do
    let(:now) { Time.zone.parse("Fri, 15 Jun 2018 10:35:57 CEST +02:00") }

    def write(timestamp)
      travel_to(timestamp) do
        {}.tap do |hash|
          yield
          cookie_jar.write(hash)
        end['Set-Cookie'].split('; ')
      end
    end

    it 'sets values as cookie' do
      cookie, _, _ = write(now) { subject.set('my-file', 'txt') }
      value = JSON.parse(CGI.unescape(cookie.match(%{async_downloads=(.*)})[1]))
      expect(value).to eq(['name' => 'my-file', 'type' => 'txt'])
    end

    it 'sets path' do
      _, path, _= write(now) { subject.set('my-file', 'txt') }
      expect(path).to eq "path=/"
    end

    it 'sets expires' do
      _, _, expires = write(now) { subject.set('my-file', 'txt') }
      expires_at = Time.zone.parse(expires.match(%{expires=(.*)})[1])
      expect(expires_at).to eq now + 1.day
    end

    it 'updates expires when new entry is added' do
      write(now) { subject.set('my-file', 'txt') }
      _, _, expires = write(now + 1.day) { subject.set('my-file', 'txt') }
      expires_at = Time.zone.parse(expires.match(%{expires=(.*)})[1])
      expect(expires_at).to eq now + 2.day
    end
  end
end
