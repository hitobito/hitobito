group_ids = Group.where(type: [Group::State, Group::Federation].map(&:to_s)).pluck(:id)
kinds = Event::Kind.all

def seed_course(group_id, kind)
  number = rand(1000)
  year = ::Date.today.year
  date = ::Date.new(year) + rand(1000) - 500 # days
  
  event = Event::Course.seed(:name, :group_id, 
    { group_id: group_id,
      name: "#{kind.short_name} #{number}",
      kind_id: kind.id,
      number: number,
      application_opening_at: date,
      application_closing_at: date + 60}
  ).first
  
  seed_dates(event, date + 90)
  seed_questions(event)
end

def seed_dates(event, date)
  rand(3).times do 
    Event::Date.seed(:event_id, :start_at,
     {event_id: event.id,
      label: 'Vorweekend',
      start_at: date += rand(10),
      finish_at: date += rand(3)}
    )
  end
  
  Event::Date.seed(:event_id, :start_at,
   {event_id: event.id,
    label: 'Kurs',
    start_at: date += rand(20),
    finish_at: date += 7 + rand(5)}
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

srand(42)

group_ids.each do |group_id|
  20.times do
    seed_course(group_id, kinds.shuffle.first)
  end
end


