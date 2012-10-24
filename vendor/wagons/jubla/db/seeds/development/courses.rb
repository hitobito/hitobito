puts group_ids = Group.where(type: [Group::State, Group::Federation].map(&:to_s)).order(:name).pluck(:id)
puts kinds = Event::Kind.order(:label)
puts "\n" * 10
@@people_count = Person.count

def seed_course(group_id, kind)
  number = rand(1000)
  year = ::Date.today.year
  date = Time.new(year) + rand(1000).days - 500.days

  location = [Faker::Address.street_address,
              Faker::Address.zip,
              Faker::Address.city].join("\n")
  
  event = Event::Course.seed(:name, :group_id, 
    { group_id: group_id,
      name: "#{kind.short_name} #{number}",
      kind_id: kind.id,
      number: number,
      state: Event::Course.possible_states.shuffle.first,
      maximum_participants: rand(30) + 10,
      priorization: true,
      location: location,
      motto: Faker::Lorem.paragraphs(rand(1..3)).join("\n"),
      description: Faker::Lorem.paragraphs(rand(1..3)).join("\n"),
      requires_approval: true,
      application_opening_at: date,
      application_closing_at: date + 60.days}
  ).first
  
  seed_dates(event, date + 90.days)
  seed_questions(event)
  seed_leaders(event)
  seed_participants(event)
end

def seed_dates(event, date)
  rand(3).times do 
    Event::Date.seed(:event_id, :start_at,
     {event_id: event.id,
      label: 'Vorweekend',
      start_at: date += rand(10).days,
      finish_at: date += rand(3).days}
    )
  end
  
  Event::Date.seed(:event_id, :start_at,
   {event_id: event.id,
    label: 'Kurs',
    start_at: date += rand(20).days,
    finish_at: date += 7 + rand(5).days}
  )
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
    p = seed_event_role(event, Event::Course::Role::Participant)
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
    alt = Event::Course.where(kind_id: participation.event.kind_id).
                        offset((Event::Course.count * rand_course).to_i).
                        limit(2).
                        pluck(:id)
    a = participation.build_application
    a.priority_1_id = participation.event_id
    a.priority_2_id = alt.first
    a.priority_3_id = alt.last
    a.save!
    participation.application = a
    participation.save!
  end
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
  
  event.questions.order(:question).each do |q|
    Event::Answer.seed_once(:participation_id, :question_id,
      {participation_id: p.id,
       question_id: q.id,
       answer: q.choices? ? q.choice_items.shuffle.first : Faker::Lorem.sentence(1)}
    )
  end
  
  p
end

srand(42)

group_ids.each do |group_id|
  20.times do
    seed_course(group_id, kinds.shuffle.first)
  end
end


