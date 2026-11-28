# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventResource < ApplicationResource
  primary_endpoint "events", [:index, :show]

  self.readable_class = EventReadables
  self.acceptable_scopes += %w[events]

  self.polymorphic = [
    "EventResource",
    "Event::CourseResource"
  ]

  with_options writable: false, filterable: false, sortable: false do
    attribute(:group_ids, :array_of_integers) { @object.group_ids }
    attribute :type, :string
    attribute :kind_id, :integer, filterable: true
    attribute :name, :string
    attribute :description, :string do
      @object.plain_text_description
    end
    attribute :description_html, :string do
      @object.description
    end
    attribute :application_conditions, :string
    attribute :motto, :string
    attribute :cost, :string
    attribute :location, :string
    attribute :application_opening_at, :date
    attribute :application_closing_at, :date
    attribute :application_contact_id, :integer
    attribute :external_applications, :boolean
    attribute :external_application_link, :string do
      next unless @object.external_applications?

      params = {group_id: @object.groups.first.id, id: @object.id}
      context.group_public_event_url(params)
    end
    attribute :maximum_participants, :integer
    attribute :participations_visible, :boolean
    attribute :created_at, :datetime
    attribute :updated_at, :datetime, filterable: true
  end

  attribute :required_contact_attrs, :array_of_strings,
    writable: false, filterable: false, sortable: false do
    (@object.class.mandatory_contact_attrs + @object.required_contact_attrs.map(&:to_sym))
      .uniq.map(&:to_s)
  end
  attribute :hidden_contact_attrs, :array_of_strings,
    writable: false, filterable: false, sortable: false do
    @object.hidden_contact_attrs.map(&:to_s)
  end
  attribute :places_available, :boolean,
    writable: false, filterable: false, sortable: false do
    @object.places_available?
  end
  attribute :waiting_list_available, :boolean,
    writable: false, filterable: false, sortable: false do
    @object.waiting_list_available?
  end
  attribute :external_application_possible, :boolean,
    writable: false, filterable: false, sortable: false do
    @object.external_applications? && @object.application_possible?
  end

  extra_attribute :privacy_policies, :array do
    privacy_policies_of(@object.groups.first)
  end

  belongs_to :contact, resource: PersonResource, writable: false,
    base_scope: ::Person.all # hitobito/hitobito_pbs#466
  has_one :contact_details, resource: Event::ContactDetailsResource, writable: false,
    foreign_key: :id
  belongs_to :kind, resource: Event::KindResource, writable: false
  has_many :dates, resource: Event::DateResource, writable: false
  has_many :participations, resource: Event::ParticipationResource, writable: false
  has_many :questions, resource: Event::QuestionResource, writable: false

  filter :type, only: [:eq] do
    eq do |scope, types|
      types_with_nil = types.map { |type| (type == "null") ? nil : type }
      scope.where(type: types_with_nil)
    end
  end

  filter :group_id, :integer, only: [:eq, :not_eq] do
    eq do |scope, group_ids|
      scope.select("events.*").references(:groups).where(groups: {id: group_ids})
    end
    not_eq do |scope, group_ids|
      scope.where.not(id: Event.joins(:groups).where(groups: {id: group_ids}).select(:id))
    end
  end

  filter :before_or_on, :date, single: true, only: [:eq] do
    eq { |scope, date| scope.before_or_on(date) }
  end

  filter :after_or_on, :date, single: true, only: [:eq] do
    eq { |scope, date| scope.after_or_on(date) }
  end

  filter :application_open, :boolean, single: true, only: [:eq] do
    eq do |scope, open|
      open_ids = Event.where(external_applications: true).application_period_open.select(:id)
      open ? scope.where(id: open_ids) : scope.where.not(id: open_ids)
    end
  end

  filter :kind_category_id, :integer, only: [:eq] do
    eq do |scope, kind_category_ids|
      scope.select("events.*")
        .joins(kind: :kind_category)
        .where(kind: {kind_category_id: kind_category_ids})
    end
  end

  def base_scope
    super.includes(:groups, :translations)
  end

  private

  def privacy_policies_of(group)
    @privacy_policies ||= {}
    @privacy_policies[group.layer_group_id] ||=
      Group::PrivacyPolicyFinder.for(group:).all.map do |policy|
        {
          group_id: policy[:group].id,
          group_name: policy[:group].to_s,
          title: policy[:title],
          url: context.rails_storage_proxy_url(policy[:group].privacy_policy.blob)
        }
      end
  end
end
