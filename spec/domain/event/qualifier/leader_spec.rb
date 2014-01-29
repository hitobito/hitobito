require 'spec_helper'

describe 'Event::Qualifier for leader' do
  include_context 'qualifier context'

  let(:participant_role) { Event::Role::Leader }
  let(:quali_date)       { Date.new(2012, 10, 20) }
  let(:event_kind)       { event_kinds(:slk) }

  it 'qualifier is of correct type' do
    qualifier.should be_a Event::Qualifier::Leader
  end


  context '#issue' do
    context 'without qualifications' do
      it_does_not_create_any_qualifications

      context 'with additional participant role' do
        before { create_participant_role }

        it_does_not_create_any_qualifications
      end
    end

    context 'with existing :sl(qualification) qualification' do
      before { create_qualification(date, :sl) }

      context 'does not prolong long expired qualification' do
        let(:date) { Date.new(2005, 3, 15) }

        it_does_not_create_any_qualifications
      end

      context 'prolongs reactivatable qualification' do
        let(:date)  { Date.new(2005, 3, 15) }
        let(:years) { quali_date.year - date.year }
        before      { qualification_kinds(:sl).update_column(:reactivateable, years) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'prolongs active qualification' do
        let(:date) { Date.new(2012, 3, 15) }

        it_creates_qualifications_of_kinds(:sl)
      end

      context 'does not prolong qualification issued on date as qualification' do
        let(:date) { quali_date }

        it 'raises exeception' do
          expect { qualifier.issue }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end

    context 'with existing :gl(prolongation) qualification' do
      before { create_qualification(date, :gl) }

      context 'created before quali date' do
        let(:date) { Date.new(2012, 3, 15) }
        it_does_not_create_any_qualifications
      end
    end

    context 'prolongs multiple' do
      before do
        event_kind.qualification_kinds << qualification_kinds(:gl)
        create_qualification(quali_date - 1.year, :sl)
        create_qualification(quali_date - 1.year, :gl)
      end

      it_creates_qualifications_of_kinds :gl, :sl
    end

    context 'prolongs duplicates only once' do
      before do
        create_qualification(Date.new(2011, 10, 3), :sl)
        create_qualification(Date.new(2010, 10, 3), :sl)
      end

      it_creates_qualifications_of_kinds :sl
    end
  end

  context '#revoke' do
    it 'removes only prolongations obtained on quali_date' do
      create_qualification(quali_date, :gl)
      create_qualification(quali_date, :sl)

      expect { qualifier.revoke }.to change { person.qualifications.count }.by(-1)
      person.qualifications.map(&:qualification_kind).should_not include qualification_kinds(:sl)
    end
  end


  context '#nothing_changed?' do
    it 'is false if event_kind has no qualifications to prolong' do
      event_kind.qualification_kinds.destroy_all

      qualifier.issue
      qualifier.should_not be_nothing_changed
    end

    it 'is false if prologation was created' do
      create_qualification(Date.new(2012, 3, 10), :sl)

      qualifier.issue
      qualifier.should_not be_nothing_changed
    end

    it 'is true if no existing qualification could not be prolonged' do
      event_kind.qualification_kinds << qualification_kinds(:gl)
      create_qualification(Date.new(2009, 3, 10), :gl)
      create_qualification(Date.new(2007, 3, 10), :sl)

      qualifier.issue
      qualifier.should be_nothing_changed
    end
  end

end
