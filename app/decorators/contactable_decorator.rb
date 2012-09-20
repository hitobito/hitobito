module ContactableDecorator
  
  def complete_address
    html = ''.html_safe

    if address?
      html << h.simple_format(address)
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
    attr_tag(:address, html) 
  end

  def prim_email
    html = ''.html_safe
    if email.present?
      html << h.mail_to(email)
    end
    attr_tag(:email, html) 
  end

  def all_phone_numbers
    html = ''.html_safe 
    phone_numbers.each do |n|
      num = ''.html_safe
      num << n.number
      num << h.muted(n.label)
      html << h.simple_format(num)
    end
    attr_tag(:phone_numbers, html) 
  end

  def all_social_accounts
    html = ''.html_safe
    social_accounts.each do |s|
      sa = ''.html_safe
      if s.label == 'E-Mail'
        sa << h.mail_to(s.name)
      else
        sa << s.name
      end
      sa << h.muted(s.label)
      html << h.simple_format(sa)
    end
    attr_tag(:social_accounts, html) 
  end

  private
  # pack content into a special tag with attribute name if content not empty ... <foo_attr> content </foo_attr>
  def attr_tag(tag, html)
    if html.empty?
      html
    else
      h.content_tag(tag, html)
    end
  end

end
