class EventSeeder

  @@kinds = Event::Kind.order(:label)
  @@people_count = Person.count

  def seed_event(group_id, type)
    values = event_values(group_id)
    case type
    when :course then seed_course(values)
    when :base then seed_base_event(values)
    end
  end

  def event_values(group_id)
    number = rand(1000)
    year = ::Date.today.year
    date = Time.new(year) + rand(1000).days - 500.days

    values = { group_ids: [group_id],
      number: number,
      maximum_participants: rand(30) + 10,
      location: event_location,
      motto: Faker::Lorem.sentence,
      description: Faker::Lorem.paragraphs(rand(1..3)).join("\n"),
      requires_approval: true,
      application_opening_at: date,
      application_closing_at: date + 60.days}
  end

  def event_location
    [Faker::Address.street_address,
     Faker::Address.zip,
     Faker::Address.city].join("\n")
  end

  def seed_base_event(values)
    date, number = values[:application_opening_at], values[:number]
    event = Event.seed(:name, values.merge(name: "Anlass #{number}")).first
    seed_dates(event, date + 90.days)
    seed_questions(event) if true?
    seed_leaders(event)
    5.times do
      seed_event_role(event, event.class.participant_type)
    end
  end

  def seed_course(values)
    event = Event::Course.seed(:name, course_attributes(values)).first

    seed_dates(event, values[:application_opening_at] + 90.days)
    seed_questions(event)
    seed_leaders(event)
    seed_participants(event)

    event
  end

  def course_attributes(values)
     kind = @@kinds.shuffle.first
     values.merge({
        name: "#{kind.short_name} #{values[:number]}",
        kind_id: kind.id,
        #state: Event::Course.possible_states.shuffle.first,
        priorization: true,
        requires_approval: true})
  end

  def seed_dates(event, date)
    rand(3).times do
      date = seed_date(event, 'Vorweekend', date, 10, 3)
    end
    seed_date(event, event.class.label, date, 20, 14)
  end

  def seed_date(event, label, date, start_range, finish_range)
    Event::Date.seed(:event_id, :start_at,
     {event_id: event.id,
      label: label,
      start_at: date += rand(20).days,
      finish_at: date += 7 + rand(5).days}
    )
    date
  end

  def seed_questions(event)
    Event::Question.global.limit(rand(4)).each do |q|
      Event::Question.seed(:event_id, :question,
       {event_id: event.id,
        question: q.question,
        choices: q.choices}
      )
    end
  end

  def seed_leaders(event)
    seed_event_role(event, Event::Role::Leader)
    seed_event_role(event, Event::Role::AssistantLeader)
    seed_event_role(event, Event::Role::Cook)
    seed_event_role(event, Event::Role::Treasurer)
    seed_event_role(event, Event::Role::Speaker)
  end

  def seed_participants(event)
    5.times do
      p = seed_event_role(event, event.class.participant_type)
      seed_application(p)
    end

    5.times do
      p = seed_participation(event)
      seed_application(p)
    end
  end

  def seed_application(participation)
    # generate random value no matter if application exists or not
    prio = rand(3) + 1
    rand_course = rand
    unless participation.application
      alt = alternative_course_id(participation, rand_course)
      a = participation.build_application
      a.priority_1_id = participation.event_id
      a.priority_2_id = alt.first
      a.priority_3_id = alt.last
      a.save!
      participation.application = a
      participation.save!
    end
  end

  def alternative_course_id(participation, rand_course)
     Event::Course.where(kind_id: participation.event.kind_id).
                   offset((Event::Course.count * rand_course).to_i).
                   limit(2).
                   pluck(:id)
  end

  def seed_event_role(event, role_type)
    p = seed_participation(event)
    role_type.seed_once(:participation_id, {participation_id: p.id})
    p
  end

  def seed_participation(event)
    person_id = Person.offset(rand(@@people_count)).limit(1).pluck(:id).first

    p = Event::Participation.seed(:event_id, :person_id,
      {event_id: event.id,
       person_id: person_id}
    ).first

    seed_answers(p)
    p
  end

  def seed_answers(participation)
    participation.event.questions.order(:question).each do |q|
      Event::Answer.seed_once(:participation_id, :question_id,
        {participation_id: participation.id,
         question_id: q.id,
         answer: q.choices? ? q.choice_items.shuffle.first : Faker::Lorem.sentence(1)}
      )
    end
  end

  def course_group_ids
    Group.course_offerers.pluck(:id)
  end

  def true?
    [true, false].sample
  end

end
