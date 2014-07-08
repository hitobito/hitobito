require 'spec_helper'

describe Event::Qualifier do
  let(:event_kind) { event_kinds(:slk) }
  let(:course) do
    event = Fabricate(:course, kind: event_kind)
    event.dates.create!(start_at: quali_date, finish_at: quali_date)
    event
  end

  let(:participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
    participation
  end

  let(:leader_participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
    participation
  end

  let(:hybrid_participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
    participation
  end

  let(:participant)      { participation.person }
  let(:leader)           { leader_participation.person }
  let(:hybrid)           { hybrid_participation.person }

  let(:participant_qualifier) { Event::Qualifier.for(participation) }
  let(:leader_qualifier) { Event::Qualifier.for(leader_participation) }
  let(:hybrid_qualifier) { Event::Qualifier.for(hybrid_participation) }
  let(:quali_date)       { Date.new(2012, 10, 20) }

  def create_qualification(person, date, kind)
    Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(kind), start_at: date)
  end

  def obtained_qualification_kinds(person)
    person.qualifications.where(start_at: quali_date, origin: course.name).
                          map(&:qualification_kind)
  end

  def self.it_does_not_create_any_qualifications(person)
    it 'does not create any qualifications for #{person}' do
      qualifier = person == :leader ? leader_qualifier : participant_qualifier
      person = send(person)

      expect { qualifier.issue }.not_to change { person.reload.qualifications.count }
      obtained_qualification_kinds(person).should be_empty
    end
  end

  def self.it_creates_qualifications_of_kinds(person, *kinds)
    it "creates qualifications for #{person} (#{kinds})" do
      qualifier = person == :leader ? leader_qualifier : participant_qualifier
      person = send(person)

      expect { qualifier.issue }.to change { person.reload.qualifications.count }.by(kinds.size)
      kinds.each { |kind| obtained_qualification_kinds(person).should include qualification_kinds(kind) }
    end
  end

  def self.it_does_not_create_qualifications_of_kinds(person, *kinds)
    it "does not create qualifications for #{person} (#{kinds})" do
      qualifier = person == :leader ? leader_qualifier : participant_qualifier
      person = send(person)

      qualifier.issue
      person.reload
      kinds.each { |kind| obtained_qualification_kinds(person).should_not include qualification_kinds(kind) }
    end
  end

  it 'has correct role for participant ' do
    participant_qualifier.role.should eq 'participant'
  end

  it 'has correct role for leader' do
    leader_qualifier.role.should eq 'leader'
  end

  it 'has correct role for leader that is also participant' do
    hybrid_qualifier.role.should eq 'leader'
  end

  context '#issue' do
    context 'for participant without qualifications' do
      it_creates_qualifications_of_kinds(:participant, :sl)
      it_does_not_create_qualifications_of_kinds(:participant, :sl_leader, :gl)
    end

    context 'for leader without qualifications' do
      it_creates_qualifications_of_kinds(:leader, :sl_leader)
      it_does_not_create_qualifications_of_kinds(:leader, :sl, :gl)

      context 'with additional participant role' do
        before do
          # TODO: why person with two participations and not only two roles/same participation?
          Fabricate(Event::Course::Role::Participant.name.to_sym,
                    participation: Fabricate(:event_participation, event: course))
        end

        it_creates_qualifications_of_kinds(:leader, :sl_leader)
        it_does_not_create_qualifications_of_kinds(:leader, :sl, :gl)
      end
    end

    context 'for leader/participant without qualifications' do
      it_creates_qualifications_of_kinds(:hybrid, :sl_leader, :sl)
      it_does_not_create_qualifications_of_kinds(:hybrid, :gl)
    end

    context 'with existing :sl (qualification) qualification' do
      before { create_qualification(participant, date, :sl) }

      context 'that is expired' do
        let(:date) { Date.new(2005, 3, 15) }

        it_creates_qualifications_of_kinds(:participant, :sl)
      end

      context 'that is active' do
        let(:date) { Date.new(2010, 3, 15) }

        it_creates_qualifications_of_kinds(:participant, :sl)
      end

      context 'that is newer' do
        let(:date) { Date.new(2013, 3, 15) }

        it_creates_qualifications_of_kinds(:participant, :sl)
      end

      context 'that was create on same quali_date ' do
        let(:date) { quali_date }

        it_does_not_create_any_qualifications(:participant)
      end
    end

    context 'with existing :gl (prolongation) qualification' do
      before { create_qualification(participant, date, :gl) }

      context 'does not prolong long expired qualification' do
        let(:date) { Date.new(2005, 3, 15) }

        it_creates_qualifications_of_kinds(:participant, :sl)
      end

      context 'prolongs reactivatable qualification' do
        let(:date)  { Date.new(2005, 3, 15) }
        let(:years) { quali_date.year - date.year }
        before      { qualification_kinds(:gl).update_column(:reactivateable, years) }

        it_creates_qualifications_of_kinds(:participant, :sl, :gl)
      end

      context 'prolongs active qualification' do
        let(:date) { Date.new(2012, 3, 15) }

        it_creates_qualifications_of_kinds(:participant, :sl, :gl)
      end

      context 'does not prolong qualification issued on same date as qualification' do
        let(:date) { quali_date }

        it_creates_qualifications_of_kinds(:participant, :sl)
      end
    end

    context 'prolongs multiple' do
      before do
        event_kind.event_kind_qualification_kinds.create!(qualification_kind_id: qualification_kinds(:gl).id,
                                                          category: 'qualification',
                                                          role: 'participant')
        create_qualification(participant, quali_date - 1.year, :sl)
        create_qualification(participant, quali_date - 1.year, :gl)
      end

      it_creates_qualifications_of_kinds(:participant, :gl, :sl)
    end

    context 'prolongs duplicates only once' do
      before do
        create_qualification(participant, Date.new(2011, 10, 3), :sl)
        create_qualification(participant, Date.new(2010, 10, 3), :sl)
      end

      it_creates_qualifications_of_kinds(:participant, :sl)
    end
  end

  context '#revoke' do
    it 'removes qualifications and prolongations obtained on quali_date' do
      create_qualification(participant, quali_date, :gl)
      create_qualification(participant, quali_date, :sl)
      create_qualification(participant, Date.new(2010, 3, 10), :gl)

      expect { participant_qualifier.revoke }.to change { participant.qualifications.count }.by(-2)
      participant.qualifications.map(&:qualification_kind).should_not include qualification_kinds(:sl)
      participant.qualifications.map(&:qualification_kind).should include qualification_kinds(:gl)
    end
  end

  context '#nothing_changed?' do
    it 'is false if event_kind has no qualifications to prolong' do
      event_kind.event_kind_qualification_kinds.create!(qualification_kind_id: qualification_kinds(:gl).id,
                                                        category: 'qualification',
                                                        role: 'participant')

      participant_qualifier.issue
      participant_qualifier.should_not be_nothing_changed
    end

    it 'is false if prologation was created' do
      create_qualification(participant, Date.new(2012, 3, 10), :gl)

      participant_qualifier.issue
      participant_qualifier.should_not be_nothing_changed
    end

    it 'is true if no existing qualification could not be prolonged' do
      event_kind.event_kind_qualification_kinds.destroy_all
      event_kind.event_kind_qualification_kinds.create!(qualification_kind_id: qualification_kinds(:sl).id,
                                                        category: 'prolongation',
                                                        role: 'participant')
      create_qualification(participant, Date.new(2009, 3, 10), :gl)
      create_qualification(participant, Date.new(2007, 3, 10), :sl)

      participant_qualifier.issue
      participant_qualifier.should be_nothing_changed
    end
  end
end
