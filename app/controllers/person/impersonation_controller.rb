# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::ImpersonationController < ApplicationController

  before_action :authorize_action

  def create
    person = Person.find(params[:person_id])
    return redirect_to :back if person == current_user || origin_user
    taker = current_user
    session[:origin_user] = taker.id
    sign_in(person)

    PaperTrail::Version.create(main: person, item: person, whodunnit: taker, event: :impersonate)

    if person.password? && person.email?
      Person::UserImpersonationMailer.completed(person, taker.full_name).deliver_now
    end

    redirect_to root_path
  end

  def destroy
    return redirect_to :back unless origin_user
    previous_user = current_user
    sign_in(origin_user)
    PaperTrail::Version.create(main: previous_user,
                               item: previous_user,
                               whodunnit: origin_user,
                               event: :impersonation_done)

    session[:origin_user] = nil
    redirect_to person_home_path(previous_user)
  end

  private

  def authorize_action
    if action_name == 'destroy'
      authorize!(:show, Person)
    else
      authorize!(:impersonate_user, Person)
    end
  end
end
