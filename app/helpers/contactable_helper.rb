module ContactableHelper
  
  def render_phone_numbers(contactable)
    safe_join(contactable.phone_numbers) do |number|
      content_tag(:p) do
        safe_join([number.number, content_tag(:span, number.label, class: 'muted')], ' ')
      end
    end
  end
  
  def render_address(contactable)
    html = ''.html_safe
    
    if contactable.address?
      html << simple_format(contactable.address)
    end
    
    if contactable.zip_code?
      html << contactable.zip_code.to_s
    end 
    
    if contactable.town?
      html << ' '
      html << contactable.town
    end
    
    if contactable.country? && (contactable.zip_code? || contactable.town?)
      html << tag(:br)
    end
    
    if contactable.country?
      html << contactable.country
    end
    
    html
  end
end