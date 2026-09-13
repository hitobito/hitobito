# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Service discovery: clients start at the endpoint root, find the principal of
# the authenticated person there and their address books from the principal.
class Carddav::PrincipalsController < Carddav::BaseController
  def root
    render_propfind(Carddav::Resources::Root.new(address_book))
  end

  def show
    render_propfind(Carddav::Resources::Principal.new(address_book))
  end
end
