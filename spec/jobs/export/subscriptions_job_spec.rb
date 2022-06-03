# frozen_string_literal: true

#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::SubscriptionsJob do

  subject do
    Export::SubscriptionsJob.new(format, user.id, mailing_list.id,
                                 household: true, filename: 'subscription_export')
  end

  let(:mailing_list) { mailing_lists(:info) }
  let(:user) { people(:top_leader) }

  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }
  let(:file) { AsyncDownloadFile.maybe_from_filename('subscription_export', user.id, format) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]

    Fabricate(:subscription, mailing_list: mailing_list)
    Fabricate(:subscription, mailing_list: mailing_list)
  end

  context 'creates an CSV-Export' do
    let(:format) { :csv }

    it 'and saves it' do
      subject.perform


      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Name;Adresse;.*/)
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }

    it 'and saves it' do
      subject.perform

      expect(file.generated_file).to be_attached
    end
  end

end
