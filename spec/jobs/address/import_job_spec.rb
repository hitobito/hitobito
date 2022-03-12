# frozen_string_literal: true

#  Copyright (c) 2021, Schweizer Blasmusik Verband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Address::ImportJob do
  include ActiveJob::TestHelper

  let(:job) { Address::ImportJob.new }

  context 'when configured' do
    it 'runs importer' do
      expect(Settings.addresses).to receive(:url).and_return('https://addresses-archive.example.com')
      expect(Settings.addresses).to receive(:token).and_return(SecureRandom.urlsafe_base64)

      importer = double
      expect(Address::Importer).to receive(:new).and_return(importer)
      expect(importer).to receive(:run)

      job.perform
    end
  end

  context 'when url not configured' do
    it 'does not run importer' do
      expect(Settings.addresses).to receive(:url).and_return('')

      expect(Address::Importer).to_not receive(:new)

      job.perform
    end
  end
  
  context 'when token not configured' do
    it 'does not run importer' do
      expect(Settings.addresses).to receive(:token).and_return('')

      expect(Address::Importer).to_not receive(:new)

      job.perform
    end
  end
end
