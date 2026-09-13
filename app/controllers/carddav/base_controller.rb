# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Base of the read only CardDAV endpoint (RFC 6352).
#
# Authentication is done with the personal CardDAV token, which the person
# generates under their settings. CardDAV clients only know about HTTP Basic
# authentication, so the token is sent as the password; the user name is
# ignored.
class Carddav::BaseController < ApplicationController
  COMPLIANCE_CLASSES = "1, 3, addressbook"
  ALLOWED_METHODS = "OPTIONS, GET, HEAD, PROPFIND, REPORT"

  skip_authorization_check
  skip_forgery_protection
  skip_before_action :authenticate_person!
  skip_before_action :reject_blocked_person!

  prepend_before_action :authenticate_by_token!
  prepend_before_action :respond_to_options

  before_action :set_dav_headers

  private

  # The person the token belongs to takes the place of the logged in person,
  # so that abilities and stamping behave as everywhere else.
  def current_person
    @carddav_person
  end

  def authenticate_by_token!
    person = Person.find_by(carddav_token: carddav_token) if carddav_token.present?
    return request_authentication if person.nil?
    return head(:forbidden) unless may_access?(person)

    Person::PreloadGroups.for(person)
    @carddav_person = person
  end

  # A person who cannot log in at all must not get at the data of others
  # through the endpoint either, even if their token still exists.
  def may_access?(person)
    !person.blocked? && person.email? && person.password?
  end

  def carddav_token
    @carddav_token ||= authenticate_with_http_basic { |_name, password| password.presence }
  end

  def request_authentication
    response.headers["WWW-Authenticate"] = %(Basic realm="#{realm}")
    head :unauthorized
  end

  def realm
    Settings.application.name.to_s.delete('"\\')
  end

  def respond_to_options
    return unless request.request_method == "OPTIONS"

    set_dav_headers
    response.headers["Allow"] = ALLOWED_METHODS
    head :ok
  end

  def set_dav_headers
    response.headers["DAV"] = COMPLIANCE_CLASSES
  end

  def address_book
    @address_book ||= Carddav::AddressBook.new(current_person)
  end

  def dav_request
    @dav_request ||= Carddav::Request.new(request)
  end

  def render_multistatus(resources)
    render body: Carddav::Multistatus.new(resources, dav_request.properties).to_xml,
      content_type: "application/xml",
      status: :multi_status
  end

  # A collection answers for itself, and with Depth: 1 also for its members.
  def render_propfind(resource)
    render_multistatus(dav_request.depth_zero? ? [resource] : [resource, *resource.members])
  end
end
