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
      expect(person).to receive_message_chain(:qualifications, :order_by_date,
                                              { includes: { qualification_kind: :translations } })
        .and_return([])
      expect(list.qualifications).to be_empty
    end

    it 'marks first if of kind if it is reactivateable' do
      allow(list).to receive(:ordered_qualifications).and_return(
        [
          Qualification.new(qualification_kind: sl_leader)
        ]
      )
      expect(list.qualifications[0]).to be_first_reactivateable
    end

    it 'does not mark second of kind' do
      allow(list).to receive(:ordered_qualifications).and_return(
        [
          Qualification.new(qualification_kind: sl_leader),
          Qualification.new(qualification_kind: sl_leader)
        ]
      )
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does mark first of kind qualification is active' do
      allow(list).to receive(:ordered_qualifications).and_return(
        [
          Qualification.new(
            qualification_kind: sl, finish_at: 2.years.from_now.to_date
          ),
          Qualification.new(
            qualification_kind: sl, finish_at: 1.year.from_now.to_date
          )
        ]
      )
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does not mark first of kind if qualification is inactive and not reactivateable' do
      allow(list).to receive(:ordered_qualifications).and_return(
        [
          Qualification.new(
            qualification_kind: sl, finish_at: 1.year.ago.to_date
          ),
          Qualification.new(
            qualification_kind: sl, finish_at: 2.years.ago.to_date
          )
        ]
      )
      expect(list.qualifications[0]).not_to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    describe '#open_training_days' do
      let(:person) { people(:bottom_member) }
      let(:slk) { event_kinds(:slk) }
      let(:gl) { qualification_kinds(:gl).tap { |k| k.update!(required_training_days: 1) } }
      let(:qualifying_date) { Date.new(2024, 1, 1) }
      subject(:qualifications) { list.qualifications }
      before { travel_to(qualifying_date + 3.months) }

      it 'is nil if qualification is neither active nor reactivateable' do
        Fabricate(:qualification, person: person, qualification_kind: gl,
                                  start_at: qualifying_date - 3.years)
        expect(qualifications[0].open_training_days).to be_nil
      end

      it 'is nil if qualification is not active and not within reactivateable period' do
        gl.update!(reactivateable: 1)
        Fabricate(:qualification, person: person, qualification_kind: gl,
                                  start_at: qualifying_date - 3.years)
        expect(qualifications[0].open_training_days).to be_nil
      end

      it 'is present if qualification is not active and but within reactivateable period' do
        gl.update!(reactivateable: 3)
        Fabricate(:qualification, person: person, qualification_kind: gl,
                                  start_at: qualifying_date - 3.years)
        expect(qualifications[0].open_training_days).to eq 1
      end

      it 'is present if qualification is active' do
        Fabricate(:qualification, person: person, qualification_kind: gl,
                                  start_at: qualifying_date - 3.months)
        expect(qualifications[0].open_training_days).to eq 1
      end

      it 'sums trainings after qualifying_date' do
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.1, start_at: qualifying_date - 1.day)
        create_course_participation(training_days: 0.5, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date + 1.day)
        create_course_participation(training_days: 0.3, start_at: qualifying_date + 10.days)
        expect(qualifications[0].open_training_days).to eq 0.2
      end

      it 'only sets value on most recent qualification for kind' do
        Fabricate(:qualification, person: person, qualification_kind: gl,
                                  start_at: qualifying_date - 2.years)
        Fabricate(:qualification, person: person, qualification_kind: gl, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date)
        create_course_participation(training_days: 0.5, start_at: qualifying_date + 1.day)
        expect(qualifications[0].open_training_days).to eq 0.5
        expect(qualifications[1].open_training_days).to be_nil
      end
    end

    def create_course_participation(start_at:, kind: slk, qualified: true, training_days: nil)
      course = Fabricate.build(:course, kind: kind, training_days: training_days)
      course.dates.build(start_at: start_at)
      course.save!
      Fabricate(:event_participation, event: course, person: person, qualified: qualified)
    end
  end
end
