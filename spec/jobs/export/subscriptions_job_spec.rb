# frozen_string_literal: true

#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::SubscriptionsJob do
  let(:filename) { "subscription_export" }
  let(:options) { {household: true, filename: filename} }

  subject do
    Export::SubscriptionsJob.new(format, user.id, mailing_list.id, options)
  end

  let(:mailing_list) { mailing_lists(:info) }
  let(:user) { people(:top_leader) }

  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }
  let(:file) { subject.job_observation }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]

    Fabricate(:subscription, mailing_list: mailing_list)
    Fabricate(:subscription, mailing_list: mailing_list)
    subject.enqueue!
    subject.perform
  end

  context "creates an CSV-Export" do
    let(:format) { :csv }

    it "and saves it" do
      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Name;zusätzliche Adresszeile;Strasse;.*/)
    end

    context "with selection" do
      let(:options) { {selection: true, filename: filename} }

      it "and saves it" do
        subject.perform

        lines = file.read.lines
        expect(lines.size).to eq(3)
      end
    end
  end

  context "creates an Excel-Export" do
    let(:format) { :xlsx }

    it "and saves it" do
      expect(file.generated_file).to be_attached
    end

    context "with selection" do
      let(:options) { {selection: true, filename: filename} }

      it "and saves it" do
        subject.perform

        expect(file.generated_file).to be_attached
      end
    end
  end
end
