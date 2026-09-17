# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The URLs of the resources exposed over CardDAV. Collections are referenced
# with a trailing slash, as clients resolve relative references against them.
module Carddav::Hrefs
  module_function

  # The endpoint is not inside the language scope, hence never carries a locale.
  NO_LOCALE = {locale: nil}.freeze

  def root = collection(routes.carddav_root_path(NO_LOCALE))

  def principal = collection(routes.carddav_principal_path(NO_LOCALE))

  def home = collection(routes.carddav_home_path(NO_LOCALE))

  def address_book = collection(routes.carddav_address_book_path(NO_LOCALE))

  def contact(person) = routes.carddav_contact_path(NO_LOCALE.merge(id: person.id))

  # The person id in a contact href, as sent by a client in an
  # addressbook-multiget report, be it a path or an absolute url.
  def contact_id(href) = href.to_s[%r{/(\d+)\.vcf\z}, 1]

  def routes = Rails.application.routes.url_helpers

  def collection(path) = path.end_with?("/") ? path : "#{path}/"
end
