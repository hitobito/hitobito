module Event::CampHelper
  def format_event_advisor_id(event)
    if event.advisor_id
      assoc_link(event.advisor)
    else
      '(Niemand)'
    end
  end
  
  def format_event_coach_id(event)
    if event.coach_id
      assoc_link(event.coach)
    else
      '(Niemand)'
    end
  end
end