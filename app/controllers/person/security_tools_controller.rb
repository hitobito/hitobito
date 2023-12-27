#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SecurityToolsController < ApplicationController

  PASSWORD_COMPROMISED_SITUATION = 'password_compromised_situation'
  PASSWORD_COMPROMISED_SOLUTION = 'password_compromised_solution'
  EMAIL_COMPROMISED_SITUATION = 'email_compromised_situation'
  EMAIL_COMPROMISED_SOLUTION = 'email_compromised_solution'
  DATALEAK_SITUATION = 'dataleak_situation_id'
  DATALEAK_SOLUTION = 'dataleak_solution_id'
  SUSPEND_PERSON_SITUATION = 'suspend_person_situation_id'
  SUSPEND_PERSON_SOLUTION = 'suspend_person_solution_id'
  BLOCKED_PERSON_TITLE = 'blocked_person_title_id'
  BLOCKED_PERSON_SITUATION = 'blocked_person_situation_id'
  BLOCKED_PERSON_SOLUTION = 'blocked_person_solution_id'
  BLOCKED_PERSON_INTERVAL = 'blocked_person_interval_id'

  before_action :authorize_action

  decorates :group, :person, :security_tools

  helper_method :person_has_login, :person_has_two_factor, :person, :herself, :group,
  :password_compromised_situation_text, :password_compromised_solution_text,
  :email_compromised_situation_text, :email_compromised_solution_text,
  :dataleak_situation_text, :dataleak_solution_text,
  :suspend_person_situation_text, :suspend_person_solution_text,
  :blocked_person_situation_text, :blocked_person_solution_text, :blocked_person_interval_text

  def index
    respond_to do |format|
      format.html do
        load_info_texts
      end
      format.js do
        load_groups_and_roles_that_see_me
      end
    end
  end

  def password_override
    person.encrypted_password = nil
    person.save
    notify
    if herself?
      sign_out_and_redirect(current_user)
    else
      redirect_to group_person_path(group, person), notice: t('.flashes.success')
    end
  end

  def block_person
    if !herself? && !herself_through_impersonation? &&
        Person::BlockService.new(person, current_user: current_user).block!
      redirect_to security_tools_group_person_path(group, person), notice: t('.flashes.success')
    else
      redirect_to security_tools_group_person_path(group, person), alert: t('.flashes.error')
    end
  end

  def unblock_person
    if !herself? && !herself_through_impersonation? &&
        Person::BlockService.new(person, current_user: current_user).unblock!
      redirect_to security_tools_group_person_path(group, person), notice: t('.flashes.success')
    else
      redirect_to security_tools_group_person_path(group, person), alert: t('.flashes.error')
    end
  end

  private

  def person
    @person ||= fetch_person
  end

  def herself?
    person.id == current_user.id
  end

  def herself_through_impersonation?
    person.id == origin_user&.id
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def notify
    PaperTrail::Version.create(main: person,
                               item: person,
                               whodunnit: current_user,
                               event: :password_override)

    if person.email?
      Person::UserPasswordOverrideMailer.send_mail(person, current_user.full_name).deliver
    end
  end

  def get_content(key, placeholders = nil)
    content = CustomContent.get(key)
    placeholders ||= {
      'person-name' => h(person.full_name)
    }
    content.body_with_values(placeholders).to_s.html_safe
  end

  def authorize_action
    authorize!(:update, person)
  end

  # rubocop:disable Layout/LineLength
  def load_info_texts
    @password_compromised_situation_text = get_content(Person::SecurityToolsController::PASSWORD_COMPROMISED_SITUATION)
    @password_compromised_solution_text= get_content(Person::SecurityToolsController::PASSWORD_COMPROMISED_SOLUTION)
    @email_compromised_situation_text = get_content(Person::SecurityToolsController::EMAIL_COMPROMISED_SITUATION)
    @email_compromised_solution_text = get_content(Person::SecurityToolsController::EMAIL_COMPROMISED_SOLUTION)
    @dataleak_situation_text = get_content(Person::SecurityToolsController::DATALEAK_SITUATION)
    @dataleak_solution_text = get_content(Person::SecurityToolsController::DATALEAK_SOLUTION)
    @suspend_person_situation_text = get_content(Person::SecurityToolsController::SUSPEND_PERSON_SITUATION)
    @suspend_person_solution_text = get_content(Person::SecurityToolsController::SUSPEND_PERSON_SOLUTION)
    @blocked_person_title_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_TITLE)
    @blocked_person_situation_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_SITUATION)
    @blocked_person_solution_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_SOLUTION)
    if Person::BlockService.inactivity_block_interval_placeholders.values.all?(&:present?)
      @blocked_person_interval_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_INTERVAL,
                                                  Person::BlockService.inactivity_block_interval_placeholders)
    end
  end
  # rubocop:enable Layout/LineLength

  def model_class
    Person
  end

  def load_groups_and_roles_that_see_me
    @groups_and_roles_that_see_me = groups_and_roles_that_see_me
  end

  def groups_and_roles_that_see_me
    groups_and_roles = {}
    relevant_groups.each do |group_id, group_name, group_type|
      group_type.constantize.role_types.each do |role_type|
        next unless can_see_me?(role_type, group_id)

        groups_and_roles[group_id] ||= { name: group_name, roles: [] }
        groups_and_roles[group_id][:roles] << role_type.label
      end
    end
    groups_and_roles
  end

  def relevant_groups
    @relevant_groups ||= Group.where(layer_group_id: relevant_layer_ids)
                              .order_by_type
                              .pluck(:id, :name, :type)
  end

  def relevant_layer_ids
    @relevant_layer_ids ||= person.groups.flat_map(&:layer_hierarchy).map(&:id).uniq
  end

  def can_see_me?(role_type, group_id)
    return false if role_type.permissions.empty?

    test_person = Ability.new(Person.new(roles: [role_type.new(group_id: group_id)]))
    test_person.can?(:show_details, person)
  end
end
