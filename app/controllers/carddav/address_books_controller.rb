# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The addressbook home set and the single address book in it, holding everybody
# the authenticated person may see.
class Carddav::AddressBooksController < Carddav::BaseController
  QUERY_REPORT = "addressbook-query"
  MULTIGET_REPORT = "addressbook-multiget"

  def index
    render_propfind(Carddav::Resources::Home.new(address_book))
  end

  def show
    render_propfind(resource)
  end

  def report
    case dav_request.report_name
    when QUERY_REPORT then render_multistatus(resource.members)
    when MULTIGET_REPORT then render_multistatus(multiget_resources)
    else head :bad_request
    end
  end

  private

  def resource
    @resource ||= Carddav::Resources::AddressBook.new(address_book)
  end

  def multiget_resources
    requested = dav_request.hrefs.index_with { |href| Carddav::Hrefs.contact_id(href) }
    people = address_book.find_all(requested.values.compact)

    requested.collect do |href, id|
      person = people[id.to_i] if id
      person ? resource.contact(person) : Carddav::Resources::Missing.new(href)
    end
  end
end
