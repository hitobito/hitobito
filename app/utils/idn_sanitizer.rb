# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
    if email.strip =~ /[^\w@\.\-]/ # simple regexp to skip most unaffected addresses
      parts = email.strip.split('@')
      domain = parts.last
      suffix = ''
      if domain.ends_with?('>')
        domain = domain[0..-2]
        suffix = '>'
      end
      "#{parts.first}@#{SimpleIDN.to_ascii(domain)}#{suffix}"
    else
      email
    end
  end
end