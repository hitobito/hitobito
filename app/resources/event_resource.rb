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
    attribute :description, :string
    attribute :application_conditions, :string
    attribute :state, :string, filterable: true
    attribute :number, :string
    attribute :motto, :string
    attribute :cost, :string
    attribute :location, :string
    attribute :application_opening_at, :date
    attribute :application_closing_at, :date
    attribute :participant_count, :integer
    attribute :training_days, :float
    attribute :application_contact_id, :integer
    attribute :applicant_count, :integer
    attribute :teamer_count, :integer
    attribute :external_application_link, :string do
      next unless @object.external_applications?

      params = { group_id: @object.groups.first.id, id: @object.id }
      context.group_public_event_url(params)
    end
    attribute :maximum_participants, :integer
    attribute :minimum_participants, :integer
    attribute :leaders, :array_of_strings do
      @object.participations.flat_map do |p|
        [p.person.first_name, p.person.last_name].reject(&:blank?).compact.join(' ')
      end
    end
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
    Event.includes(:groups, :translations).list
  end

  def index_ability
    JsonApi::EventAbility.new(current_ability)
  end

  def resolve(scope)
    leaders = Event::Participation.joins(:roles).where({
      event_roles: { type: [
        Event::Role::Leader.sti_name,
        Event::Role::AssistantLeader.sti_name
      ] }
    })
    ActiveRecord::Associations::Preloader.new.preload(leaders, :person, Person.only_public_data)
    ActiveRecord::Associations::Preloader.new.preload(scope, :participations, leaders)
    scope.to_a
  end
end
