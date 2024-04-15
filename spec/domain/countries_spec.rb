# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Countries do
  context '#label' do
    it 'returns the label for the given country code' do
      expect(Countries.label('CH')).to eq 'Schweiz'
    end

    it 'returns the label for the given country code in the given language' do
      expect(Countries.label('CH', locale: :it)).to eq 'Svizzera'
    end

    it 'returns the country code if no label is found' do
      expect(Countries.label('ZZ')).to eq 'ZZ'
    end
  end
end
