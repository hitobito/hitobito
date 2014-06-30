# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Duration do

  context '#cover?' do
    let(:start) { Time.zone.parse('2013-10-10 10:30') }
    let(:finish) { Time.zone.parse('2013-10-12 10:30') }
    let(:now) { Time.zone.parse('2013-10-11 10:30') }

    subject { Duration.new(start, finish) }

    context 'between start finish' do
      it { should be_cover(now) }
    end

    context 'without finish' do
      let(:finish) { nil }
      it { should be_cover(now) }
    end

    context 'without start' do
      let(:start) { nil }
      it { should be_cover(now) }
    end

    context 'without start or finish' do
      let(:start) { nil }
      let(:finish) { nil }
      it { should_not be_cover(now) }
    end

  end

end
