require 'spec_helper'

describe 'Event::Qualifier for participant' do
  include_context 'qualifier context'

  let(:participant_role) { Event::Role::Participant }
  let(:quali_date)       { Date.new(2012, 10, 20) }
  let(:event_kind)       { event_kinds(:slk) }

  it 'qualifier is of correct type' do
    qualifier.should be_a Event::Qualifier::Participant
  end

  context '#issue' do

    context 'without qualifications' do
      it_creates_qualifications_of_kinds(:sl)
    end

    context 'with existing :sl (qualification) qualification' do
      before { create_qualification(date, :sl) }

      context 'that is expired' do
        let(:date) { Date.new(2005, 3, 15) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'that is active' do
        let(:date) { Date.new(2010, 3, 15) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'that is newer' do
        let(:date) { Date.new(2013, 3, 15) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'that was create on same quali_date ' do
        let(:date) { quali_date }

        it 'raises exeception' do
          expect { qualifier.issue }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end

    context 'with existing :gl (prolongation) qualification' do
      before { create_qualification(date, :gl) }

      context 'does not prolong long expired qualification' do
        let(:date) { Date.new(2005, 3, 15) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'prolongs reactivatable qualification' do
        let(:date)  { Date.new(2005, 3, 15) }
        let(:years) { quali_date.year - date.year }
        before      { qualification_kinds(:gl).update_column(:reactivateable, years) }

        it_creates_qualifications_of_kinds(:sl, :gl)
      end

      context 'prolongs active qualification' do
        let(:date) { Date.new(2012, 3, 15) }

        it_creates_qualifications_of_kinds(:sl, :gl)
      end

      context 'does not prolong qualification issued on same date as qualification' do
        let(:date) { quali_date }

        it 'raises exeception' do
          expect { qualifier.issue }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  context '#revoke' do
    it 'removes qualifications and prolongations obtained on quali_date' do
      create_qualification(quali_date, :gl)
      create_qualification(quali_date, :sl)
      create_qualification(Date.new(2010,3,10), :gl)

      expect { qualifier.revoke }.to change { person.qualifications.count }.by(-2)
      person.qualifications.map(&:qualification_kind).should_not include qualification_kinds(:sl)
      person.qualifications.map(&:qualification_kind).should include qualification_kinds(:gl)
    end
  end

  context '#nothing_changed?' do
    it 'is false if event_kind has no qualifications to prolong' do
      event_kind.prolongations.destroy_all

      qualifier.issue
      qualifier.should_not be_nothing_changed
    end

    it 'is false if prologation was created' do
      create_qualification(Date.new(2012, 3, 10), :gl)

      qualifier.issue
      qualifier.should_not be_nothing_changed
    end

    it 'is true if no existing qualification could not be prolonged' do
      event_kind.qualification_kinds.destroy_all
      event_kind.prolongations << qualification_kinds(:sl)
      create_qualification(Date.new(2009, 3, 10), :gl)
      create_qualification(Date.new(2007, 3, 10), :sl)

      qualifier.issue
      qualifier.should be_nothing_changed
    end
  end
end
