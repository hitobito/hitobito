# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::RegisterController < CrudController
  skip_authorization_check
  skip_authorize_resource

  after_create :sign_in_person

  before_action :assert_honeypot_is_empty, only: [:create]

  before_action :redirect_to_group, unless: :registration_active?

  private

  def build_entry
    role = super
    role.group = group
    role.type = group.self_registration_role_type
    role.person = Person.new(person_attrs)
    role
  end

  def save_entry
    entry.person.save && entry.save
  end

  def return_path
    super.presence || edit_group_person_path(entry.group_id, entry.person_id) if valid?
  end

  def sign_in_person
    sign_in(entry.person)
  end

  def assert_honeypot_is_empty
    if params.delete(:verification).present?
      redirect_to new_person_session_path
    end
  end

  def redirect_to_group
    redirect_to group_path(group)
  end

  def registration_active?
    group.self_registration_role_type.present? &&
      Settings.groups&.self_registration&.activated
  end

  def valid?
    entry.valid? && entry.person.valid?
  end

  def person_attrs
    model_params&.delete(:new_person)
      &.permit(*PeopleController.permitted_attrs)
      &.merge(primary_group_id: group.id)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authenticate?
    false
  end

  def path_args(entry)
    [group, entry]
  end

  def self.model_class
    @model_class ||= Role
  end
end
