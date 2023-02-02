# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonResource < ApplicationResource
  primary_endpoint 'people', [:index, :show, :update]

  ACTION_SHOW_DETAILS = :show_details
  ACTION_SHOW_FULL = :show_full

  def base_scope
    # TODO: should restrict scope with current_ability
    # Person.accessible_by(PersonReadables.new(current_ability.user))

    super
  end

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :nickname, :string
  attribute :company_name, :string
  attribute :company, :boolean
  attribute :email, :string
  attribute :address, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string
  attribute :gender, :string, readable: :show_details?, writable: :write_details?
  attribute :birthday, :date, readable: :show_details?, writable: :write_details?
  attribute :primary_group_id, :integer, except: [:writeable]

  def self.contactable_has_many(name)
    polymorphic_has_many name, as: :contactable do
      # work-around to make relation readable only if user has `:show_details` permission on person
      params do |hash, people, context|
        permitted_people = people.select do |person|
          context.current_ability.can?(ACTION_SHOW_DETAILS, person)
        end

        hash[:filter][:contactable_type] = 'Person'
        hash[:filter][:contactable_id] = permitted_people.map(&:id)
      end
      # TODO: fix writable: :write_details? => this should be fixed in specific resource
      # (e.g. in `PhoneNumberResource`), possibly on `#base_scope`
    end
  end
  private_class_method :contactable_has_many

  contactable_has_many :phone_numbers
  contactable_has_many :social_accounts
  contactable_has_many :additional_emails

  # TODO: fix writable: :write_details? => this should be fixed in `RoleResource`, possibly on `#base_scope`
  has_many :roles do
    params do |hash, people, context|
      permitted_people = people.select do |person|
        context.current_ability.can?(ACTION_SHOW_FULL, person)
      end

      hash[:filter][:person_id] = permitted_people.map(&:id)
    end
  end

  filter :updated_at, :datetime, single: true do
    eq do |scope, value|
      scope.where(updated_at: value..)
    end
  end

  def show_full?(model_instance)
    can?(ACTION_SHOW_FULL, model_instance)
  end

  def show_details?(model_instance)
    can?(ACTION_SHOW_DETAILS, model_instance)
  end

  def write_details?
    # no model_instance method argument is given when writable is called,
    # so we have to access current entry by controller context
    can?(ACTION_SHOW_DETAILS, context.entry)
  end
end
