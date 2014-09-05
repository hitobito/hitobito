# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Duration do

  let(:duration) { Duration.new(start, finish) }

  context '#cover?' do
    let(:start) { Time.zone.parse('2013-10-10 10:30') }
    let(:finish) { Time.zone.parse('2013-10-12 10:30') }
    let(:now) { Time.zone.parse('2013-10-11 10:30') }

    subject { duration }


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

  context '#days' do
    subject { duration.days }

    context 'with finish_at' do
      let(:start)  { Time.zone.parse('2013-10-10 22:30') }
      let(:finish) { Time.zone.parse('2013-10-12 09:30') }

      it 'returns number of days including start and finish' do
        should eq 3
      end
    end

    context 'without finish_at' do
      let(:start)  { Time.zone.parse('2013-10-10 10:30') }
      let(:finish) { nil }

      it 'defaults to 1' do
        should eq 1
      end
    end
  end

end
