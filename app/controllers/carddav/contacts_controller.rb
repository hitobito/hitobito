# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# A single person as a vCard resource.
class Carddav::ContactsController < Carddav::BaseController
  before_action :entry

  def show
    response.headers["ETag"] = resource.etag
    render body: resource.vcard, content_type: Carddav::Resources::Contact::CONTENT_TYPE
  end

  def propfind
    render_propfind(resource)
  end

  private

  def entry
    @entry = address_book.find(params[:id])
    head(:not_found) if @entry.nil?
  end

  def resource
    @resource ||= Carddav::Resources::Contact.new(address_book, @entry)
  end
end
