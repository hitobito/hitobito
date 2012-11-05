module FlockHelper
  
  def format_group_advisor_id(group)
    if group.advisor_id
      assoc_link(group.advisor)
    else
      '(Niemand)'
    end
  end
  
  def format_group_coach_id(group)
    if group.coach_id
      assoc_link(group.coach)
    else
      '(Niemand)'
    end
  end
end