module IdnSanitizer
  module_function

  def sanitize(email_or_array)
    if email_or_array.respond_to?(:each)
      email_or_array.collect { |email| sanitize_idn(email) }
    else
      sanitize_idn(email_or_array)
    end
  end

  def sanitize_idn(email)
    if email =~ /[^\w@\.\-]/ # simple regexp to skip most unaffected addresses
      parts = email.split('@')
      "#{parts.first}@#{SimpleIDN.to_ascii(parts.last)}"
    else
      email
    end
  end
end