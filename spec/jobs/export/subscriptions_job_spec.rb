#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::SubscriptionsJob do
  subject { Export::SubscriptionsJob.new(format, user.id, mailing_list.id, household: true, filename: "subscription_export") }

  let(:mailing_list) { mailing_lists(:info) }
  let(:user) { people(:top_leader) }

  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }
  let(:filepath) { AsyncDownloadFile::DIRECTORY.join("subscription_export") }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]

    Fabricate(:subscription, mailing_list: mailing_list)
    Fabricate(:subscription, mailing_list: mailing_list)
  end

  context "creates an CSV-Export" do
    let(:format) { :csv }

    it "and saves it" do
      subject.perform

      lines = File.readlines("#{filepath}.#{format}")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Name;Adresse;.*/)
    end
  end

  context "creates an Excel-Export" do
    let(:format) { :xlsx }

    it "and saves it" do
      subject.perform

      expect(File.exist?("#{filepath}.#{format}"))
    end
  end
end
