#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::ImpersonationController < ApplicationController
  before_action :authorize_action
  skip_before_action :reject_blocked_person!, only: [:destroy]

  def create
    person = Person.find(params[:person_id])
    return redirect_back_with_fallback if person == current_user || origin_user
    return redirect_back_with_fallback(alert: t(".email_must_be_confirmed")) if login_unconfirmed?(person)

    start_impersonation(person)
    redirect_to root_path
  end

  def destroy
    return redirect_back(fallback_location: root_path) unless origin_user
    previous_user = current_user

    stop_impersonation(previous_user)
    redirect_to person_home_path(previous_user)
  end

  private

  def authorize_action
    if action_name == "destroy"
      authorize!(:show, Person)
    else
      authorize!(:impersonate_user, Person)
    end
  end

  def start_impersonation(person)
    taker = current_user
    session[:origin_user] = taker.id
    sign_in(person)

    PaperTrail::Version.create(main: person, item: person, whodunnit: taker, event: :impersonate)

    if person.password? && person.email? && Settings.impersonate.notify
      Person::UserImpersonationMailer.completed(person, taker.full_name).deliver_later
    end
  end

  def stop_impersonation(previous_user)
    sign_in(origin_user)
    PaperTrail::Version.create(main: previous_user,
      item: previous_user,
      whodunnit: origin_user,
      event: :impersonation_done)

    session[:origin_user] = nil
  end

  def redirect_back_with_fallback(options = {})
    redirect_back(fallback_location: root_path, **options)
  end

  def login_unconfirmed?(person) = person.login_status == :login && !person.confirmed?
end
