require "spec_helper"

describe Event::Qualifier do
  let(:event_kind) { event_kinds(:slk) }
  let(:course) do
    event = Fabricate(:course, kind: event_kind)
    event.dates.create!(start_at: quali_date, finish_at: quali_date)
    event
  end

  let(:participation) do
    participation = Fabricate(:event_participation, event: course, participant: participant)
    Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
    participation.reload
  end

  let(:leader_participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
    participation.reload
  end

  let(:hybrid_participation) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
    Fabricate(Event::Role::Leader.name.to_sym, participation: participation)
    participation.reload
  end

  let(:participant) { Fabricate(:person) }
  let(:leader) { leader_participation.person }
  let(:hybrid) { hybrid_participation.person }

  let(:participant_qualifier) { Event::Qualifier.for(participation) }
  let(:leader_qualifier) { Event::Qualifier.for(leader_participation) }
  let(:hybrid_qualifier) { Event::Qualifier.for(hybrid_participation) }
  let(:quali_date) { Date.new(2012, 10, 20) }

  def create_qualification(person, date, kind)
    Fabricate(:qualification,
      person: person,
      qualification_kind: qualification_kinds(kind),
      start_at: date,
      qualified_at: date)
  end

  def obtained_qualification_kinds(person)
    person.qualifications.where(start_at: quali_date, origin: course.name)
      .map(&:qualification_kind)
  end

  def person_qualifier(person)
    case person
    when :leader then leader_qualifier
    when :hybrid then hybrid_qualifier
    when :participant then participant_qualifier
    else fail("No Qualifier defined for person #{person}")
    end
  end

  def self.it_does_not_create_any_qualifications(person)
    it "does not create any qualifications for #{person}" do
      qualifier = person_qualifier(person)
      person = send(person)

      expect { qualifier.issue }.not_to change { person.reload.qualifications.count }
      expect(obtained_qualification_kinds(person)).to be_empty
    end
  end

  def self.it_creates_qualifications_of_kinds(person, *kinds)
    it "creates qualifications for #{person} (#{kinds})" do
      qualifier = person_qualifier(person)
      person = send(person)

      expect { qualifier.issue }.to change { person.reload.qualifications.count }.by(kinds.size)
      kinds.each { |kind| expect(obtained_qualification_kinds(person)).to include qualification_kinds(kind) }
    end
  end

  def self.it_does_not_create_qualifications_of_kinds(person, *kinds)
    it "does not create qualifications for #{person} (#{kinds})" do
      qualifier = person_qualifier(person)
      person = send(person)

      qualifier.issue
      person.reload
      kinds.each { |kind| expect(obtained_qualification_kinds(person)).not_to include qualification_kinds(kind) }
    end
  end

  it "has correct role for participant " do
    expect(participant_qualifier.role).to eq "participant"
  end

  it "has correct role for leader" do
    expect(leader_qualifier.role).to eq "leader"
  end

  it "has correct role for leader that is also participant" do
    expect(hybrid_qualifier.role).to eq "leader"
  end

  context "#revoke" do
    it "removes qualifications and prolongations obtained on quali_date" do
      create_qualification(participant, quali_date, :gl)
      create_qualification(participant, quali_date, :sl)
      create_qualification(participant, Date.new(2010, 3, 10), :gl)

      expect { participant_qualifier.revoke }.to change { participant.qualifications.count }.by(-2)
      expect(participant.qualifications.map(&:qualification_kind)).not_to include qualification_kinds(:sl)
      expect(participant.qualifications.map(&:qualification_kind)).to include qualification_kinds(:gl)
    end
  end

  context "#nothing_changed?" do
    it "is false if event_kind has no qualifications to prolong" do
      event_kind.event_kind_qualification_kinds.create!(qualification_kind_id: qualification_kinds(:gl).id,
        category: "qualification",
        role: "participant")

      participant_qualifier.issue
      expect(participant_qualifier).not_to be_nothing_changed
    end

    it "is false if prologation was created" do
      create_qualification(participant, Date.new(2012, 3, 10), :gl)

      participant_qualifier.issue
      expect(participant_qualifier).not_to be_nothing_changed
    end

    it "is true if no existing qualification could not be prolonged" do
      event_kind.event_kind_qualification_kinds.destroy_all
      event_kind.event_kind_qualification_kinds.create!(qualification_kind_id: qualification_kinds(:sl).id,
        category: "prolongation",
        role: "participant")
      create_qualification(participant, Date.new(2009, 3, 10), :gl)
      create_qualification(participant, Date.new(2007, 3, 10), :sl)

      participant_qualifier.issue
      expect(participant_qualifier).to be_nothing_changed
    end
  end

  # based on SAC definitions as described in
  # https://github.com/hitobito/hitobito_sac_cas/issues/1645
  context "prolongations conditional to required training days" do
    let(:gl) { qualification_kinds(:gl) }
    let(:sl) { qualification_kinds(:sl) }

    def obtained_qualification(person, origin, kind)
      person.qualifications.find_by(origin: origin, qualification_kind: kind)
    end

    def create_course_participation(start_at:, training_days: nil)
      course = Fabricate.build(:course, name: "Kurs #{start_at.year}", kind: event_kind, training_days: training_days)
      course.dates.build(start_at: start_at)
      course.save!
      Fabricate(:event_participation, event: course, participant: participant, qualified: true)
    end

    def create_event_kind_qualification_kind(event_kind, qualification_kind)
      Event::KindQualificationKind.create!(
        event_kind: event_kind,
        qualification_kind: qualification_kind,
        category: :prolongation,
        role: :participant
      )
    end

    before do
      event_kind_qualification_kinds(:slksl_qual).destroy

      gl.update!(required_training_days: 3, validity: 6, reactivateable: 4)
    end

    let!(:initial_qualification) { create_qualification(participant, Date.new(2010, 3, 10), :gl) }

    it "noops if current course does not have required trainings days" do
      participation = create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 2.5)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if current course has required trainings days" do
      participation = create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 3)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2012, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2012, 6, 1)
    end

    it "prolongs if current course at end of validity period has required trainings days" do
      participation = create_course_participation(start_at: Date.new(2016, 6, 1), training_days: 3)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2016, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2016, 6, 1)
    end

    it "prolongs if current course at end of reactivateable period has required trainings days" do
      participation = create_course_participation(start_at: Date.new(2020, 6, 1), training_days: 3)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2020, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2020, 6, 1)
    end

    it "noops if current and previous courses combined do not have required training days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2014, 4, 1), training_days: 1.5)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if current and previous courses combined have required trainings days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 1)
      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)

      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2012, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2016, 4, 1)
    end

    it "prolongs at matching course date if current and previous courses combined have required trainings days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 2)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2014, 3, 1)
      expect(qualification.qualified_at).to eq Date.new(2016, 4, 1)
    end

    it "prolongs at course date if current course alone has required trainings days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 3)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2016, 4, 1)
      expect(qualification.qualified_at).to eq Date.new(2016, 4, 1)
    end

    it "prolongs if current and existing courses combined have required training days in reactivatable period" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2018, 4, 1), training_days: 1)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2012, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2018, 4, 1)
    end

    it "noop if current and existing courses combined do not have required training days in validity period" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2019, 4, 1), training_days: 1)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if current and existing courses combined have required training days in validity period" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2019, 4, 1), training_days: 2)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2014, 3, 1)
      expect(qualification.qualified_at).to eq Date.new(2019, 4, 1)
    end

    it "prolongs iterativly if current and existing courses combined have required training days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 1)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      expect { Event::Qualifier.for(participation18).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation18.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2014, 3, 1)
      expect(qualification.qualified_at).to eq Date.new(2018, 10, 1)
    end

    it "prolongs iterativly if current and existing courses combined have more than required training days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 2)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      expect { Event::Qualifier.for(participation18).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation18.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2016, 4, 1)
      expect(qualification.qualified_at).to eq Date.new(2018, 10, 1)
    end

    it "noops if current and existing courses combined do not have newly required training days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 2)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)
      # quali starting in 2014

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      expect { Event::Qualifier.for(participation18).issue }.to change { participant.qualifications.count }.by(1)
      # quali starting in 2016

      participation19 = create_course_participation(start_at: Date.new(2019, 2, 1), training_days: 1)
      expect { Event::Qualifier.for(participation19).issue }.not_to change { participant.qualifications.count }
      # quali still starting in 2016
    end

    it "prolongs if current and existing courses combined have newly required training days" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 2)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      expect { Event::Qualifier.for(participation18).issue }.to change { participant.qualifications.count }.by(1)

      participation19 = create_course_participation(start_at: Date.new(2019, 2, 1), training_days: 2)
      expect { Event::Qualifier.for(participation19).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation19.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2018, 10, 1)
      expect(qualification.qualified_at).to eq Date.new(2019, 2, 1)
    end

    it "prolongs if current and existing courses combined have newly required training days (other combination)" do
      create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 1)
      create_course_participation(start_at: Date.new(2014, 3, 1), training_days: 1)
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 2)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 2)
      expect { Event::Qualifier.for(participation18).issue }.to change { participant.qualifications.count }.by(1)

      participation19 = create_course_participation(start_at: Date.new(2019, 2, 1), training_days: 1)
      expect { Event::Qualifier.for(participation19).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation19.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2018, 10, 1)
      expect(qualification.qualified_at).to eq Date.new(2019, 2, 1)
    end

    it "noops if current courses combined do not have newly required training days after full training" do
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 3)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      participation18 = create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      expect { Event::Qualifier.for(participation18).issue }.not_to change { participant.qualifications.count }
    end

    it "noops if current and previous courses combined do not have newly required training days after full training" do
      participation16 = create_course_participation(start_at: Date.new(2016, 4, 1), training_days: 3)
      expect { Event::Qualifier.for(participation16).issue }.to change { participant.qualifications.count }.by(1)

      create_course_participation(start_at: Date.new(2018, 10, 1), training_days: 1)
      participation20 = create_course_participation(start_at: Date.new(2020, 7, 1), training_days: 1)
      expect { Event::Qualifier.for(participation20).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if current and existing mini courses combined have required training days" do
      create_course_participation(start_at: Date.new(2011, 2, 1), training_days: 0.5)
      create_course_participation(start_at: Date.new(2012, 3, 1), training_days: 0.5)
      create_course_participation(start_at: Date.new(2013, 4, 1), training_days: 0.5)
      create_course_participation(start_at: Date.new(2014, 5, 1), training_days: 0.5)
      create_course_participation(start_at: Date.new(2015, 6, 1), training_days: 0.5)
      participation = create_course_participation(start_at: Date.new(2016, 7, 1), training_days: 0.5)
      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)

      qualification = obtained_qualification(participant, participation.event.name, gl)
      expect(qualification.start_at).to eq Date.new(2011, 2, 1)
      expect(qualification.qualified_at).to eq Date.new(2016, 7, 1)
    end

    it "prolongs multiple matching qualifications" do
      sl.update!(required_training_days: 2, validity: 1)
      create_event_kind_qualification_kind(course.kind, sl)
      participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 3)
      create_qualification(participant, Date.new(2012, 3, 10), :sl)
      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(2)
    end

    it "prolongs multiple matching qualifications from two different courses" do
      sl.update!(required_training_days: 2, validity: 1)
      create_event_kind_qualification_kind(event_kinds(:slk), sl)

      create_qualification(participant, Date.new(2011, 11, 1), :sl)
      create_course_participation(start_at: Date.new(2012, 2, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 2)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(2)

      sl_quali = obtained_qualification(participant, participation.event.name, sl)
      expect(sl_quali.start_at).to eq Date.new(2012, 9, 1)
      expect(sl_quali.qualified_at).to eq Date.new(2012, 9, 1)

      gl_quali = obtained_qualification(participant, participation.event.name, gl)
      expect(gl_quali.start_at).to eq Date.new(2012, 2, 1)
      expect(gl_quali.qualified_at).to eq Date.new(2012, 9, 1)
    end

    context "with existing qualification and required training days met" do
      before do
        create_course_participation(start_at: Date.new(2012, 1, 1), training_days: 3)
      end

      it "noops if qualification has been issued in previous course in same year" do
        initial_qualification.update(start_at: Date.new(2012, 1, 1), qualified_at: Date.new(2012, 1, 1))
        participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 1)
        expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
      end

      it "noops if qualification has been issued manually without qualified_at" do
        initial_qualification.update(start_at: Date.new(2012, 1, 1), qualified_at: nil)
        participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 1)
        expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
      end

      it "noops if qualification has been issued manually after computed start_at" do
        initial_qualification.update(start_at: Date.new(2012, 2, 1), qualified_at: nil)
        participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 1)
        expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
      end

      it "creates an later qualification if qualification has been issued manually on before start_at" do
        initial_qualification.update(start_at: Date.new(2011, 12, 1), qualified_at: nil)
        participation = create_course_participation(start_at: Date.new(2012, 9, 1), training_days: 1)
        expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
        qualification = obtained_qualification(participant, participation.event.name, gl)
        expect(qualification.start_at).to eq Date.new(2012, 1, 1)
        expect(qualification.qualified_at).to eq Date.new(2012, 9, 1)
      end
    end
  end
end
