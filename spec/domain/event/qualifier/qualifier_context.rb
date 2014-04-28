shared_context 'qualifier context'  do

  let(:course) do
    event = Fabricate(:course, kind: event_kind)
    event.dates.create!(start_at: quali_date, finish_at: quali_date)
    event
  end

  let(:participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(participant_role.name.to_sym, participation: participation)
    participation
  end

  let(:person) { participation.person }
  let(:qualifier) { Event::Qualifier.for(participation) }

  def create_qualification(date, kind)
    Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(kind), start_at: date)
  end

  def create_participant_role
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: course))
  end

  def obtained_qualification_kinds
    person.qualifications.where(start_at: quali_date, origin: course.name).map(&:qualification_kind)
  end

  def self.it_does_not_create_any_qualifications
    it 'does not create any qualifications' do
      expect { qualifier.issue }.not_to change { person.reload.qualifications.count }
      obtained_qualification_kinds.should be_empty
    end
  end

  def self.it_creates_qualifications_of_kinds(*kinds)
    it "creates qualifications (#{kinds})" do
      expect { qualifier.issue }.to change { person.reload.qualifications.count }.by(kinds.size)
      kinds.each { |kind| obtained_qualification_kinds.should include qualification_kinds(kind) }
    end
  end
end
