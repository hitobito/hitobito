module AutoLinkHelper
  
  def auto_link(str)
    if email?(str)
      mail_to(str)
    elsif url_with_protocol?(str)
      link_to(str, str, target: '_blank')
    elsif url_without_protocol?(str)
      url = "http://" + str
      link_to(str, url, target: '_blank')
    else
      str
    end
  end
  
  private

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