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

  before_action :authorize_action, :load_info_texts, :load_groups_and_roles_that_see_me

  decorates :group, :person, :security_tools

  helper_method :person_has_login, :person_has_two_factor, :person, :herself, :group,
  :password_compromised_situation_text, :password_compromised_solution_text,
  :email_compromised_situation_text, :email_compromised_solution_text,
  :dataleak_situation_text, :dataleak_solution_text,
  :suspend_person_situation_text, :suspend_person_solution_text

  respond_to :html

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

  private

  def person
    @person ||= fetch_person
  end

  def herself?
    person.id == current_user.id
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

  def get_content(key)
    content = CustomContent.get(key)
    placeholders = {
      'person-name' => h(person.full_name)
    }
    content.body_with_values(placeholders).to_s.html_safe
  end

  def authorize_action
    authorize!(:update, person)
  end

  # rubocop:disable Metrics/LineLength
  def load_info_texts
    @password_compromised_situation_text = get_content(Person::SecurityToolsController::PASSWORD_COMPROMISED_SITUATION)
    @password_compromised_solution_text= get_content(Person::SecurityToolsController::PASSWORD_COMPROMISED_SOLUTION)
    @email_compromised_situation_text = get_content(Person::SecurityToolsController::EMAIL_COMPROMISED_SITUATION)
    @email_compromised_solution_text = get_content(Person::SecurityToolsController::EMAIL_COMPROMISED_SOLUTION)
    @dataleak_situation_text = get_content(Person::SecurityToolsController::DATALEAK_SITUATION)
    @dataleak_solution_text = get_content(Person::SecurityToolsController::DATALEAK_SOLUTION)
    @suspend_person_situation_text = get_content(Person::SecurityToolsController::SUSPEND_PERSON_SITUATION)
    @suspend_person_solution_text = get_content(Person::SecurityToolsController::SUSPEND_PERSON_SOLUTION)
  end
  # rubocop:enable Metrics/LineLength

  def model_class
    Person
  end

  def load_groups_and_roles_that_see_me
    @groups_and_roles_that_see_me ||= groups_and_roles_that_see_me
  end

  def groups_and_roles_that_see_me
    groups_and_roles = {}
    all_groups.each do |group_id, group_name, group_type|
      group_type.constantize.role_types.each do |role|
        next unless can_see_me?(role, group_id, group_type)

        groups_and_roles[group_id] ||= { name: group_name, roles: [] }
        groups_and_roles[group_id][:roles] << role.label
      end
    end
    groups_and_roles
  end

  def all_groups
    @all_groups ||= Group.order_by_type.pluck(:id, :name, :type)
  end

  # def all_groups
  #   @all_groups ||= Group.where(id: relevant_group_ids).order_by_type.pluck(:id, :name, :type)
  # end

  # def relevant_group_ids
  #   @relevant_group_ids ||= person.groups.flat_map { |g| g.hierarchy }.flat_map { |g| g.sister_groups_with_descendants }.map(&:id).uniq
  # end

  def can_see_me?(role, group_id, group_type)
    return false if group_type != role.name.deconstantize

    test_person = Ability.new(Person.new(roles: [role.new(group_id: group_id)]))
    test_person.can?(:show_details, person)
  end


end
