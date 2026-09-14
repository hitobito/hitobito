# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The XML namespaces used by WebDAV (RFC 4918) and CardDAV (RFC 6352). The
# calendarserver namespace is not standardized, but its getctag property is
# what every client uses to detect changes in an address book.
module Carddav::Namespaces
  DAV = "DAV:"
  CARDDAV = "urn:ietf:params:xml:ns:carddav"
  CALENDARSERVER = "http://calendarserver.org/ns/"

  PREFIXES = {DAV => "d", CARDDAV => "card", CALENDARSERVER => "cs"}.freeze
end
