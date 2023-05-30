# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonResource < ApplicationResource
  primary_endpoint 'people', [:index, :show, :update]

  def authorize_update(model)
    if model.changed_attribute_names_to_save & ['gender', 'birthday']
      # show_details ability is required additionally for updating gender, birthday
      update_ability.authorize!(:show_details, model)
    end

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
  attribute :primary_group_id, :integer, writable: false
  attribute :gender, :string, readable: :show_details?, writable: :write_details?
  attribute :birthday, :date, readable: :show_details?, writable: :write_details?

  FeatureGate.if :person_language do
    attribute :language, :string
  end

  belongs_to :primary_group, resource: GroupResource, writable: false

  has_one :layer_group, resource: GroupResource, writable: false do
    params do |hash, people|
      hash[:filter] = { id: people.flat_map {|person| person.primary_group.layer_group_id } }
    end
    assign do |_people, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method,
      # so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end

  has_many :roles, writable: false
  polymorphic_has_many :phone_numbers, as: :contactable
  polymorphic_has_many :social_accounts, as: :contactable
  polymorphic_has_many :additional_emails, as: :contactable

  filter :updated_at, :datetime

  def index_ability
    PersonReadables.new(current_ability.user)
  end

  private

  def show_details?(model_instance)
    can?(:show_details, model_instance)
  end

  def write_details?
    # no model_instance method argument is given when writable is called,
    # so we have to access current entry by controller context
    can?(:show_details, context.entry) && can?(:update, context.entry)
  end
end
