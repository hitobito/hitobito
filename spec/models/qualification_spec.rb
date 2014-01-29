# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#  origin                :string(255)
#

require 'spec_helper'

describe Qualification do

  let(:qualification) { Fabricate(:qualification) }
  let(:person) { qualification.person }

  it 'includes qualification kind and finish_at in to_s' do
    quali = Fabricate(:qualification, qualification_kind: qualification_kinds(:sl),
                                      start_at: Date.parse('2011-3-3').to_date)
    quali.to_s.should eq 'Super Lead (bis 31.12.2013)'
  end

  describe 'creating a second qualification of identical kind with validity' do
    before     { Fabricate(:qualification, args.merge(start_at: Date.parse('2011-3-3').to_date)) }
    subject    { Fabricate.build(:qualification, args.merge(start_at: date.to_date)) }
    let(:args) { { person: person, qualification_kind: qualification_kinds(:sl), start_at: date } }

    context 'on same day' do
      let(:date) { Date.parse('2011-3-3') }
      it { should_not be_valid  }
    end

    context 'later in same year' do
      let(:date) { Date.parse('2011-5-5') }
      it { should be_valid  }
    end

    context 'in next year' do
      let(:date) { Date.parse('2012-5-5') }
      it { should be_valid  }
    end
  end


  describe '#set_finish_at' do
    let(:date) { Date.today }

    it 'set current end of year if validity is 0' do
      quali = build_qualification(0, date)
      quali.valid?

      quali.finish_at.should == date.end_of_year
    end

    it 'set respective end of year if validity is 2' do
      quali = build_qualification(2, date)
      quali.valid?

      quali.finish_at.should == (date + 2.years).end_of_year
    end

    it 'does not set year if validity is nil' do
      quali = build_qualification(nil, date)
      quali.valid?

      quali.finish_at.should be_nil
    end

    it 'does not set year if start_at is nil' do
      quali = build_qualification(2, nil)
      quali.valid?

      quali.finish_at.should be_nil
    end

    def build_qualification(validity, start_at)
      kind = Fabricate(:qualification_kind, validity: validity)
      Qualification.new(qualification_kind: kind, start_at: start_at)
    end
  end

  describe '#active' do
    subject { qualification }
    it { should be_active }
  end

  describe '.active' do
    subject { person.reload.qualifications.active }

    it 'contains from today' do
      q = Fabricate(:qualification, person: person, start_at: Date.today)
      q.should be_active
      should include(q)
    end

    it 'does contain until this year' do
      q = Fabricate(:qualification, person: person, start_at: Date.today - 2.years)
      q.should be_active
      should include(q)
    end

    it 'does not contain past' do
      q = Fabricate(:qualification, person: person, start_at: Date.today - 5.years)
      q.should_not be_active
      should_not include(q)
    end

    it 'does not contain future' do
      q = Fabricate(:qualification, person: person, start_at: Date.today + 1.day)
      q.should_not be_active
      should_not include(q)
    end
  end

  describe 'reactivateable qualification kind' do
    subject { person.reload.qualifications }

    let(:today) { Date.today }
    let(:kind) { qualification_kinds(:sl) }
    let(:start_date) { today - 1.years }
    let(:q) { Fabricate(:qualification, qualification_kind: kind, person: person, start_at: start_date) }

    context 'missing' do
      context 'active qualification' do
        it { q.should be_active }
        it { q.should be_reactivateable }
      end

      context 'expired qualification' do
        let(:start_date) { today - 3.years }

        it { q.should_not be_active }
        it { q.should_not be_reactivateable }
      end
    end

    context 'when present' do
      before { kind.update_column(:reactivateable, 2) }

      context 'active qualification' do
        it { q.should be_active }
        it { q.should be_reactivateable }
      end

      context 'expired qualification within reactivateable limit' do
        let(:start_date) { today - 3.years }

        it { q.should_not be_active }
        it { q.should be_reactivateable }
      end

      context 'expired qualification past reactivateable limit' do
        let(:start_date) { today - 5.years }

        it { q.should_not be_active }
        it { q.should_not be_reactivateable }
      end
    end

    context '#reactivateable? takes parameter' do
      let(:start_date) { today - 3.years }
      before { kind.update_column(:reactivateable, 2) }

      it { q.should be_reactivateable }
      it { q.reactivateable?(today + 2.years).should be_false }
    end
  end

end
