# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventResource < ApplicationResource
  primary_endpoint 'events', [:index, :show]

  with_options writable: false, filterable: false, sortable: false do
    attribute(:group_ids, :array_of_integers) { @object.group_ids }
    attribute :type, :string
    attribute :kind_id, :integer, filterable: true
    attribute :name, :string
    attribute :state, :string, filterable: true
    attribute :number, :string, filterable: true
    attribute :motto, :string
    attribute :cost, :string
    attribute :location, :string
    attribute :application_opening_at, :date
    attribute :application_closing_at, :date
    attribute :participant_count, :integer
    attribute :training_days, :float
    attribute :application_contact_id, :integer
    attribute :applicant_count, :integer
    attribute :maximum_participants, :integer
    attribute :created_at, :datetime
    attribute :updated_at, :datetime, filterable: true
  end

  belongs_to :contact, resource: PersonResource, writable: false
  has_many :dates, resource: Event::DateResource, writable: false

  filter :type, only: [:eq] do
    eq do |scope, types|
      types_with_nil = types.map { |type| type == "null" ? nil : type }
      scope.where(type:  types_with_nil)
    end
  end

  filter :group_id, :integer, only: [:eq, :not_eq]  do
    eq do |scope, group_ids|
      scope.references(:groups).where(groups: { id: group_ids })
    end
  end

  filter :before_or_on, :date, single: true, only: [:eq] do
    eq { |scope, date| scope.before_or_on(date) }
  end

  filter :after_or_on, :date, single: true, only: [:eq] do
    eq { |scope, date| scope.after_or_on(date) }
  end

  def base_scope
    Event.includes(:groups).list
  end

  def index_ability
    JsonApi::EventAbility.new(current_ability)
  end
end
