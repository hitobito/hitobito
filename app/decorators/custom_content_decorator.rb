# encoding: utf-8
class CustomContentDecorator < ApplicationDecorator
  
  decorates :custom_content
  
  
  def available_placeholders
    if placeholders_required? || placeholders_optional?
      list = placeholders_list.collect do |ph|
        placeholder_token(ph)
      end
      
      "Verfügbare Platzhalter: #{list.join(", ")}"
    else
      "Keine Platzhalter vorhanden"
    end
  end
  
end