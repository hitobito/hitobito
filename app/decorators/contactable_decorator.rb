module ContactableDecorator

  def address_name
    content_tag(:strong, to_s)
  end

  def complete_address
    html = ''.html_safe

    prepend_complete_address(html)

    if address?
      html << safe_join(address.split("\n"), br)
      html << br
    end

    if zip_code?
      html << zip_code.to_s
    end

    if town?
      html << ' '
      html << town
    end

    if country? && (zip_code? || town?)
      html << br
    end

    if country?
      html << country
    end

    content_tag(:p, html)
  end

  def primary_email
    if email.present?
      content_tag(:p, h.mail_to(email))
    end
  end

  def all_phone_numbers(only_public = true)
    nested_values(phone_numbers, only_public)
  end

  def all_social_accounts(only_public = true)
    nested_values(social_accounts, only_public) do |name|
      if email?(name)
        h.mail_to(name)
      elsif url_with_protocol?(name)
        h.link_to(name,name, target: '_blank')
      elsif url_without_protocol?(name)
        url = "http://" + name
        h.link_to(url, url, target: '_blank')
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

    html = h.safe_join(html, br)
    content_tag(:p, html) if html.present?
  end

  private
  
  def br
    h.tag(:br)
  end

  def prepend_complete_address(html)
  end

  def email?(str)
    /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match(str)
  end

  def url_with_protocol?(str)
    # includes no white-spaces AND includes proto://
    /(?=^\S*$)(?=([a-z]*:\/\/.*$)).*/.match(str)
  end

  def url_without_protocol?(str)
    # includes no white-spaces AND includes www.*
    /(?=^\S*$)(?=(^www\..+$)).*/.match(str)
  end

end
