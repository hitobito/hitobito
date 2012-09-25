module ContactableDecorator
  
  def complete_address
    html = ''.html_safe

    if address?
      html << address
      html << h.tag(:br)
    end
    
    if zip_code?
      html << zip_code.to_s
    end 
    
    if town?
      html << ' '
      html << town
    end
    
    if country? && (zip_code? || town?)
      html << h.tag(:br)
    end
    
    if country?
      html << country
    end
    
    content_tag(:p, html)
  end

  def primary_email
    if email.present?
      content_tag(:p, h.value_with_muted(h.mail_to(email), 'Email'))
    end
  end

  def all_phone_numbers(only_public = true)
    nested_values(phone_numbers, only_public)
  end

  def all_social_accounts(only_public = true)
    nested_values(social_accounts, only_public) do |name|
      if email?(name)
        h.mail_to(name)
      else
        name
      end
    end
  end
  
  def nested_values(values, only_public)
    html = values.collect do |v|
      if !only_public || v.public? 
        val = block_given? ? yield(v.value) : v.value
        h.value_with_muted(val, v.label)
      end
    end.compact
    
    html = h.safe_join(html, h.tag(:br))
    content_tag(:p, html) if html.present?
  end

  private
  
  def email?(str)
    /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match(str)
  end

end
