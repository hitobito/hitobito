# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Salutation do

  let(:person)     { people(:top_leader) }
  let(:salutation) { Salutation.new(person) }

  context '.available' do
    subject { Salutation.available }

    it { expect(subject).to have(1).items }
  end

  context '#label' do
    subject { salutation.label }

    it { expect(subject).to eq('Hallo [Name]') }
  end

  context '#value' do
    subject { salutation.value }

    context 'male' do
      before { person.gender = 'm' }
      it { expect(subject).to eq('Hallo Top') }
    end

    context 'female' do
      before { person.gender = 'w' }
      it { expect(subject).to eq('Hallo Top') }
    end

    context 'no gender' do
      before { person.gender = nil }
      it { expect(subject).to eq('Hallo Top') }
    end
  end
end
