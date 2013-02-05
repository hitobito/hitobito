# encoding: UTF-8
module Event::ParticipationsHelper
  
  def event_attr_with_break(attr)
    str = parent.send(attr) + tag(:br)
    str.html_safe
  end

end
