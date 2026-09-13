# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The single address book a person gets over CardDAV: everybody they are
# allowed to see in a people list, with the contact data needed for a vCard
# preloaded.
class Carddav::AddressBook
  PRELOAD = [:phone_numbers, :additional_emails].freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def people
    @people ||= accessible_people.preload(*PRELOAD).order(:last_name, :first_name, :id).to_a
  end

  def find(id)
    accessible_people.preload(*PRELOAD).find_by(id: id)
  end

  # The accessible people among the given ids, keyed by id.
  def find_all(ids)
    accessible_people.preload(*PRELOAD).where(id: ids).index_by(&:id)
  end

  def name
    I18n.t("carddav.address_book.name", application_name: Settings.application.name)
  end

  def description
    I18n.t("carddav.address_book.description",
      name: user.to_s, application_name: Settings.application.name)
  end

  # Identifies the current state of the whole address book. Clients poll it and
  # only fetch the contacts again once it differs from the one they stored.
  def ctag
    @ctag ||= Digest::MD5.hexdigest(
      accessible_people.unscope(:select).pluck(:id, :updated_at).sort
        .collect { |id, updated_at| "#{id}:#{updated_at.utc.iso8601(6)}" }.join(",")
    )
  end

  private

  def accessible_people
    Person.accessible_by(PersonReadables.new(user)).select("people.updated_at")
  end
end
