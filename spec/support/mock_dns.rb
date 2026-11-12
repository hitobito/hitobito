# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Answers all DNS lookups from RECORDS instead of querying a DNS server.
module MockDns
  MAIL_DOMAINS = %w[hitobito.ch puzzle.ch sender.com to.com].freeze

  RECORDS = MAIL_DOMAINS.each_with_object({}) do |domain, records|
    records[domain] = [Resolv::DNS::Resource::IN::MX.new(10, Resolv::DNS::Name.create("mail.#{domain}"))]
    records["mail.#{domain}"] = [Resolv::DNS::Resource::IN::A.new("192.0.2.1")]
  end.freeze

  def each_resource(name, typeclass, &)
    RECORDS.fetch(name.to_s.downcase, []).grep(typeclass).each(&)
  end
end

Resolv::DNS.prepend(MockDns)
