# encoding: utf-8

#  Copyright (c) 2018, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require_dependency "app_status/mail"

describe AppStatus::Mail do
  let(:app_status) { AppStatus::Mail.new }
  let(:cache) { Rails.cache }
  let(:mail1) { Mail.new(File.read(Rails.root.join("spec", "fixtures", "email", "simple.eml"))) }
  let(:mail2) { Mail.new(File.read(Rails.root.join("spec", "fixtures", "email", "regular.eml"))) }
  let(:seen_mails) do
    [mail1, mail2].collect do |m|
      AppStatus::Mail::SeenMail.build(m)
    end
  end

  before { cache.write(:app_status, nil) }

  after { cache.write(:app_status, nil) }

  context "mail healthy" do
    it "has no overdue mails in inbox" do
      cache.write(:app_status, {seen_mails: seen_mails})

      expect(Mail).to receive(:all).and_return([mail1, mail2])

      expect(app_status.code).to eq(:ok)

      expect(cache.read(:app_status)[:seen_mails]).to eq(seen_mails)
    end

    it "has no mails at all in inbox" do
      cache.write(:app_status, {seen_mails: seen_mails})

      expect(Mail).to receive(:all).and_return([])

      expect(app_status.code).to eq(:ok)

      expect(cache.read(:app_status)[:seen_mails]).to be_empty
    end
  end

  context "mail unhealthy" do
    it "has overdue mail in inbox" do
      seen_mails.last.first_seen = DateTime.now - 52.minutes
      cache.write(:app_status, {seen_mails: seen_mails})

      expect(Mail).to receive(:all).and_return([mail1, mail2])

      expect(app_status.code).to eq(:service_unavailable)

      expect(cache.read(:app_status)[:seen_mails]).to eq(seen_mails)
    end
  end
end
