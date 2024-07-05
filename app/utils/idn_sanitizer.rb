# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module IdnSanitizer
  module_function

  def sanitize(email_or_array)
    if email_or_array.respond_to?(:each)
      email_or_array.collect do |email|
        next nil if email.nil?

        sanitize_idn(email)
      end.compact
    else
      sanitize_idn(email_or_array)
    end
  end

  def sanitize_idn(email)
    return email unless /[^\w@\.\-]/.match?(email.strip) # simple regexp, skips most unaffected addresses

    parts = email.strip.split("@")
    domain = parts.last
    suffix = ""
    if domain.ends_with?(">")
      domain = domain[0..-2]
      suffix = ">"
    end
    "#{parts.first}@#{SimpleIDN.to_ascii(domain)}#{suffix}"
  end
end
