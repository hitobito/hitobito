# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Qualifications::List do
  let(:person) { people(:bottom_member) }

  let(:sl) { qualification_kinds(:sl) }
  let(:sl_leader) { qualification_kinds(:sl_leader) }
  let(:gl_leader) { qualification_kinds(:gl_leader) }

  subject(:list) { described_class.new(person) }

  describe '#qualifications' do
    it 'loads qualifications with kinds ordered by date' do
      expect(person).to receive_message_chain(:qualifications, :order_by_date, { includes: { qualification_kind: :translations } })
        .and_return([])
      expect(list.qualifications).to be_empty
    end

    it 'marks first if of kind if it is reactivateable' do
      allow(list).to receive(:ordered_qualifications).and_return([
        Qualification.new(qualification_kind: sl_leader),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
    end

    it 'does not mark second of kind' do
      allow(list).to receive(:ordered_qualifications).and_return([
        Qualification.new(qualification_kind: sl_leader),
        Qualification.new(qualification_kind: sl_leader),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does mark first of kind qualification is active' do
      allow(list).to receive(:ordered_qualifications).and_return([
        Qualification.new(qualification_kind: sl, finish_at: 2.years.from_now.to_date),
        Qualification.new(qualification_kind: sl, finish_at: 1.years.from_now.to_date),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does not mark first of kind if qualification is inactive and not reactivateable' do
      allow(list).to receive(:ordered_qualifications).and_return([
        Qualification.new(qualification_kind: sl, finish_at: 1.years.ago.to_date),
        Qualification.new(qualification_kind: sl, finish_at: 2.years.ago.to_date),
      ])
      expect(list.qualifications[0]).not_to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    describe '#open_training_days' do
      let(:person) { people(:bottom_member) }
      let(:slk) { event_kinds(:slk) }
      let(:gl) { qualification_kinds(:gl).tap { |k| k.update!(required_training_days: 1) } }
      let(:qualifying_date) { Date.new(2024, 1, 1) }
      subject(:qualifications) { list.qualifications }

      it 'is 0 if participation is older than before start_of qualification' do
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date - 1.day)
        expect(qualifications[0].open_training_days).to eq 1
      end

      it 'is still nil older qualification of a different kind exists' do
        Fabricate(:qualification, person: person, qualification_kind: sl, start_at: qualifying_date - 2.years)
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date - 1.day)
        expect(qualifications).to have(2).items
        expect(qualifications[0].open_training_days).to eq 1
        expect(qualifications[1].open_training_days).to be_nil
      end

      it 'returns summed open training days if participations after qualification' do
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date + 1.day)
        create_course_participation(training_days: 0.3, start_at: qualifying_date + 10.day)
        expect(qualifications[0].open_training_days).to eq 0.2
      end

      it 'is only set for first qualification' do
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date - 2.years)
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date + 1.day)
        create_course_participation(training_days: 0.3, start_at: qualifying_date + 10.day)
        expect(qualifications[0].open_training_days).to eq 0.2
        expect(qualifications[1].open_training_days).to be_nil
      end
    end

    def create_course_participation(kind: slk, qualified: true, training_days: nil, start_at:)
      course = Fabricate.build(:course, kind: kind, training_days: training_days)
      course.dates.build(start_at: start_at)
      course.save!
      Fabricate(:event_participation, event: course, person: person, qualified: qualified)
    end
  end
end
