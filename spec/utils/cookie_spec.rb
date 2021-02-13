#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Cookie do
  let(:cookie_jar) { ActionDispatch::Request.new({}).cookie_jar }
  let(:value)      { JSON.parse(cookie_jar[:cookie]) }
  let(:subject)    { described_class.new(cookie_jar, "cookie", [:name]) }

  it "set single cookie" do
    subject.set(name: "cookie")
    expect(value).to have(1).item
    expect(value.first["name"]).to eq "cookie"
  end

  it "set multiple cookies" do
    subject.set(name: "cookie1")
    subject.set(name: "cookie2")
    expect(value).to have(2).items
  end

  it "removes download from values" do
    subject.set(name: "cookie1")
    subject.set(name: "cookie2")
    subject.remove(name: "cookie1")
    expect(value).to have(1).items
    expect(value.first["name"]).to eq "cookie2"
  end

  it "removes cookie if no values are left" do
    subject.set(name: "cookie")
    subject.remove(name: "cookie")
    expect(cookie_jar).not_to have_key(:cookie)
  end

  it "does not set undefined attribute" do
    subject.set(name: "cookie", unknown: "unknown")
    expect(value.first["name"]).to eq "cookie"
    expect(value.first["unknown"]).to be_nil
  end

  context "Set-Cookie" do
    let(:now) { Time.zone.parse("Fri, 15 Jun 2018 10:35:57 CEST +02:00") }

    def write(timestamp)
      travel_to(timestamp) do
        {}.tap do |hash|
          yield
          cookie_jar.write(hash)
        end["Set-Cookie"].split("; ")
      end
    end

    it "sets values as cookie" do
      cookie, _, _ = write(now) { subject.set(name: "cookie") }
      value = JSON.parse(CGI.unescape(cookie.match(%{cookie=(.*)})[1]))
      expect(value).to eq(["name" => "cookie"])
    end

    it "sets path" do
      _, path, _= write(now) { subject.set(name: "cookie") }
      expect(path).to eq "path=/"
    end

    it "sets expires" do
      _, _, expires = write(now) { subject.set(name: "cookie") }
      expires_at = Time.zone.parse(expires.match(%{expires=(.*)})[1])
      expect(expires_at).to eq now + 1.day
    end

    it "updates expires when new entry is added" do
      write(now) { subject.set(name: "cookie") }
      _, _, expires = write(now + 1.day) { subject.set(name: "cookie") }
      expires_at = Time.zone.parse(expires.match(%{expires=(.*)})[1])
      expect(expires_at).to eq now + 2.day
    end
  end
end
