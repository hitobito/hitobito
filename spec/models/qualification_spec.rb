#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
#  origin                :string
#

require 'spec_helper'

describe Qualification do

  let(:qualification) { Fabricate(:qualification, person: person) }
  let(:person) { Fabricate(:person) }

  describe '.order_by_date' do
    subject(:scope) { described_class.order_by_date }
    let(:today) { Time.zone.today }

    def create_qualification(kind, attrs = {})
      Fabricate(:qualification, attrs.merge(
        person: people(:top_leader),
        qualification_kind: qualification_kinds(kind)
      ))
    end

    it 'orders by finish_at descending with nulls first' do
      sl = create_qualification(:sl, start_at: today) # validity 2 year
      gl = create_qualification(:gl, start_at: today) # validity 1 year
      ql = create_qualification(:ql, start_at: today) # no validity, i.e. no finished_at set

      expect(described_class.order_by_date).to eq [ql, sl, gl]
    end

    it 'orders by start_at descending if finish_at is equal' do
      sl = create_qualification(:sl, start_at: today, finish_at: 1.year.from_now)
      gl = create_qualification(:gl, start_at: today - 1.day, finish_at: 1.year.from_now)

      expect(described_class.order_by_date).to eq [sl, gl]
    end
  end

  context '#to_s' do
    it 'includes qualification kind and finish_at' do
      quali = Fabricate(:qualification, qualification_kind: qualification_kinds(:sl),
                                        start_at: Date.parse('2011-3-3').to_date,
                                        origin: 'SLK 11')
      expect(quali.to_s).to eq 'Super Lead (bis 31.12.2013)'
    end

    context :long do
      it 'includes origin and finish_at' do
        quali = Fabricate(:qualification, qualification_kind: qualification_kinds(:sl),
                                          start_at: Date.parse('2011-3-3').to_date,
                                          origin: 'SLK 11')
        expect(quali.to_s(:long)).to eq 'Super Lead (bis 31.12.2013, von SLK 11)'
      end

      it 'includes origin and no finish_at' do
        quali = Fabricate(:qualification, qualification_kind: Fabricate(:qualification_kind, validity: nil, label: 'Super Lead'),
                                          start_at: Date.parse('2011-3-3').to_date,
                                          origin: 'SLK 11')
        expect(quali.to_s(:long)).to eq 'Super Lead (von SLK 11)'
      end

      it 'includes only finish_at' do
        quali = Fabricate(:qualification, qualification_kind: qualification_kinds(:sl),
                                          start_at: Date.parse('2011-3-3').to_date)
        expect(quali.to_s(:long)).to eq 'Super Lead (bis 31.12.2013)'
      end

      it 'includes only kind' do
        quali = Fabricate(:qualification, qualification_kind: Fabricate(:qualification_kind, validity: nil, label: 'Super Lead'),
                                          start_at: Date.parse('2011-3-3').to_date)
        expect(quali.to_s(:long)).to eq 'Super Lead'
      end
    end
  end

  context 'creating a second qualification of identical kind with validity' do
    before     { Fabricate(:qualification, args.merge(start_at: Date.parse('2011-3-3').to_date)) }
    subject    { Fabricate.build(:qualification, args.merge(start_at: date.to_date)) }
    let(:args) { { person: person, qualification_kind: qualification_kinds(:sl), start_at: date } }

    context 'on same day' do
      let(:date) { Date.parse('2011-3-3') }
      it { is_expected.not_to be_valid  }
    end

    context 'later in same year' do
      let(:date) { Date.parse('2011-5-5') }
      it { is_expected.to be_valid  }
    end

    context 'in next year' do
      let(:date) { Date.parse('2012-5-5') }
      it { is_expected.to be_valid  }
    end
  end


  context '#set_finish_at' do
    let(:date) { Time.zone.today }

    it 'set current end of year if validity is 0' do
      quali = build_qualification(0, date)
      quali.valid?

      expect(quali.finish_at).to eq(date.end_of_year)
    end

    it 'set respective end of year if validity is 2' do
      quali = build_qualification(2, date)
      quali.valid?

      expect(quali.finish_at).to eq((date + 2.years).end_of_year)
    end

    it 'does not set year if validity is nil' do
      quali = build_qualification(nil, date)
      quali.valid?

      expect(quali.finish_at).to be_nil
    end

    it 'does not set year if start_at is nil' do
      quali = build_qualification(2, nil)
      quali.valid?

      expect(quali.finish_at).to be_nil
    end

    def build_qualification(validity, start_at)
      kind = Fabricate(:qualification_kind, validity: validity)
      Qualification.new(qualification_kind: kind, start_at: start_at)
    end
  end

  context '#active' do
    subject { qualification }
    it { is_expected.to be_active }
  end

  context '.active' do
    subject { person.reload.qualifications.active }

    it 'contains from today' do
      q = Fabricate(:qualification, person: person, start_at: Time.zone.today)
      expect(q).to be_active
      is_expected.to include(q)
    end

    it 'does contain until this year' do
      q = Fabricate(:qualification, person: person, start_at: Time.zone.today - 2.years)
      expect(q).to be_active
      is_expected.to include(q)
    end

    it 'does not contain past' do
      q = Fabricate(:qualification, person: person, start_at: Time.zone.today - 5.years)
      expect(q).not_to be_active
      is_expected.not_to include(q)
    end

    it 'does not contain future' do
      q = Fabricate(:qualification, person: person, start_at: Time.zone.today + 1.day)
      expect(q).not_to be_active
      is_expected.not_to include(q)
    end
  end

  context 'reactivateable qualification kind' do
    subject { person.reload.qualifications }

    let(:today) { Time.zone.today }
    let(:kind) { qualification_kinds(:sl) }
    let(:start_date) { today - 1.years }
    let!(:q) { Fabricate(:qualification, qualification_kind: kind, person: person, start_at: start_date) }

    context 'not reactivateable' do
      context 'active qualification' do
        it { expect(q).to be_active }
        it { expect(q).to be_reactivateable }
        it { expect(Qualification.reactivateable).to include q }
      end

      context 'expired qualification' do
        let(:start_date) { today - 3.years }

        it { expect(q).not_to be_active }
        it { expect(q).not_to be_reactivateable }
        it { expect(Qualification.reactivateable).not_to include q }
      end
    end

    context 'reactivateable' do
      before { kind.update_column(:reactivateable, 2) }

      context 'active qualification' do
        it { expect(q).to be_active }
        it { expect(q).to be_reactivateable }
        it { expect(Qualification.reactivateable).to include q }
      end

      context 'expired qualification within reactivateable limit' do
        let(:start_date) { today - 3.years }

        it { expect(q).not_to be_active }
        it { expect(q).to be_reactivateable }
        it { expect(Qualification.reactivateable).to include q }
      end

      context 'expired qualification past reactivateable limit' do
        let(:start_date) { today - 5.years }

        it { expect(q).not_to be_active }
        it { expect(q).not_to be_reactivateable }
        it { expect(Qualification.reactivateable).not_to include q }
      end
    end

    context 'not_active' do
      before { kind.update_column(:reactivateable, 2) }

      it { expect(Qualification.not_active).to be_blank }
      it { expect(Qualification.not_active([kind.id])).to be_blank }
      it { expect(Qualification.not_active([], today + 2.years)).to match_array([q]) }
      it { expect(Qualification.not_active([kind.id], today + 2.years)).to match_array([q]) }
    end

    context 'only_expired' do
      let(:gl_leader) { qualification_kinds(:gl_leader) }

      it { expect(Qualification.only_expired).to be_blank }
      it { expect(Qualification.only_expired([kind.id])).to be_blank }
      it { expect(Qualification.only_expired([], today + 2.years)).to match_array([q]) }
      it { expect(Qualification.only_expired([kind.id], today + 2.years)).to match_array([q]) }
      it { expect(Qualification.only_expired([-1], today + 2.years)).to be_empty }


      context 'with another reactivateable qualification' do
        let!(:gl_leader_active) {
          Fabricate(:qualification, qualification_kind: gl_leader, start_at: 1.day.ago)
        }
        it { expect(Qualification.only_expired).to be_blank }
        it { expect(Qualification.only_expired([kind.id])).to be_blank }
        it { expect(Qualification.only_expired([], today + 2.years)).to match_array([q]) }
        it { expect(Qualification.only_expired([kind.id], today + 2.years)).to match_array([q]) }
        it { expect(Qualification.only_expired([], today + 4.years)).to match_array([q, gl_leader_active]) }
        it { expect(Qualification.only_expired([kind.id, gl_leader.id], today + 4.years)).to match_array([q, gl_leader_active]) }
      end

      context 'when qualification never expires' do
        before { q.update_columns(finish_at: nil) }

        it { expect(Qualification.only_expired).to be_blank }
        it { expect(Qualification.only_expired([kind.id])).to be_blank }
        it { expect(Qualification.only_expired([], today + 2.years)).to be_blank }
        it { expect(Qualification.only_expired([kind.id], today + 2.years)).to be_blank }
      end

      context 'when qualification is reactivateable for 2 years' do
        before { kind.update_column(:reactivateable, 2) }

        it { expect(Qualification.only_expired([], today + 2.years)).to be_empty }
        it { expect(Qualification.only_expired([kind.id], today + 2.years)).to be_empty }
        it { expect(Qualification.only_expired([], today + 5.years)).to match_array([q]) }
        it { expect(Qualification.only_expired([kind.id], today + 5.years)).to match_array([q]) }
      end

      context 'when another expired qualification of same kind exists' do
        let!(:inactive) { Fabricate(:qualification, qualification_kind: kind, person: person, start_at: start_date - 10.years) }

        it { expect(Qualification.only_expired).to be_blank }
        it { expect(Qualification.only_expired([kind.id])).to be_blank }
        it { expect(Qualification.only_expired([], today + 2.years)).to match_array([inactive, q]) }
        it { expect(Qualification.only_expired([kind.id], today + 2.years)).to match_array([inactive, q]) }
      end
    end

    context 'only_reactivateable' do
      before { kind.update_column(:reactivateable, 2) }

      before do
        @reactivatable = Fabricate(:qualification, qualification_kind: kind, person: person, start_at: today - 3.year) # reactivateable
        @expired = Fabricate(:qualification, qualification_kind: kind, person: person, start_at: today - 5.years) # expired
      end

      it { expect(Qualification.only_reactivateable).to match_array([@reactivatable]) }
      it { expect(Qualification.only_reactivateable(today + 2.years)).to match_array([q]) }
      it { expect(Qualification.only_reactivateable(today + 4.years)).to be_blank }

    end

    context '#reactivateable? takes parameter' do
      let(:start_date) { today - 3.years }
      before { kind.update_column(:reactivateable, 2) }

      it { expect(q).to be_reactivateable }
      it { expect(q.reactivateable?(today + 2.years)).to be_falsey }
      it { expect(Qualification.reactivateable(today + 2.years)).not_to include q }
    end
  end

  describe '#reactivateable_until' do
    let(:today) { Time.zone.today }
    let(:qualification) { Qualification.new }

    it 'is nil when qualification_kind is not reactivateable' do
      qualification.qualification_kind = qualification_kinds(:sl)
      expect(qualification.reactivateable_until).to be_nil
    end

    it 'is nil when qualification_kind is reactivateable but finish_at is not set' do
      qualification.qualification_kind = qualification_kinds(:gl_leader)
      expect(qualification.reactivateable_until).to be_nil
    end

    it 'equals finish_at added by reactivateable years of kind' do
      qualification.finish_at = Date.new(2024, 3, 6)
      qualification.qualification_kind = qualification_kinds(:gl_leader)
      expect(qualification.reactivateable_until).to eq Date.new(2026, 3, 6)
    end
  end

  context 'paper trails', versioning: true do
    let(:person) { people(:top_leader) }

    it 'sets main on create' do
      expect do
        person.qualifications.create!(qualification_kind: qualification_kinds(:sl),
                                      origin: 'Bar',
                                      start_at: Time.zone.today)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('create')
      expect(version.main).to eq(person)
    end

    it 'sets main on update' do
      quali = person.qualifications.create!(qualification_kind: qualification_kinds(:sl),
                                            origin: 'Bar',
                                            start_at: Time.zone.today)
      expect do
        quali.update!(origin: 'Bur')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('update')
      expect(version.main).to eq(person)
    end

    it 'sets main on destroy' do
      quali = person.qualifications.create!(qualification_kind: qualification_kinds(:sl),
                                            origin: 'Bar',
                                            start_at: Time.zone.today)
      expect do
        quali.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq('destroy')
      expect(version.main).to eq(person)
    end
  end
end
