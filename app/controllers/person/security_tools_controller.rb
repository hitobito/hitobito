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

  before_action :authorize_action, :load_info_texts

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
    PaperTrail::Version.create(main: person, item: person, whodunnit: current_user, event: :password_override)

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

  def model_class
    Person
  end

end
