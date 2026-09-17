# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Stands in for an href a client asked about that does not exist, or that the
# authenticated person may not see. RFC 4918 wants those reported as a response
# with a bare status inside the multistatus.
class Carddav::Resources::Missing < Carddav::Resources::Base
  def initialize(href)
    super(nil)
    @href = href
  end

  attr_reader :href

  def status = "HTTP/1.1 404 Not Found"

  def properties = {}
end
