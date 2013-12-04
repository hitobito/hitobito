# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterController < ApplicationController

  helper_method :resource, :entry, :group, :event

  before_filter :assert_external_application_possible
  before_filter :assert_honeypot_is_empty, only: [:check, :register]

  def index
    session[:person_return_to] = show_event_path
    flash.now[:notice] = "Du musst dich einloggen um dich für den Anlass '#{event.to_s}' anzumelden."
  end

  def check
    if params[:person][:email].present?
      if user = Person.find_by_email(params[:person][:email])
        Event::SendRegisterLoginJob.new(user, group, event).enqueue!
        flash.now[:notice] = "Wir haben dich in unserer Datenbank gefunden.\n\n" +
                             'Wir haben dir ein E-Mail mit einem Link geschickt, ' +
                             'wo du dich direkt für den Anlass anmelden kannst.'
        render 'index'
      else
        @person = Person.new(email: params[:person][:email])
        flash.now[:notice] = 'Bitte fülle das folgende Formular aus, bevor du dich für den Anlass anmeldest.'
        render 'register'
      end
    else
      flash.now[:alert] = 'Bitte gib eine Emailadresse ein'
      render 'index'
    end
  end

  def register
    if create_person
      sign_in(:person, person)
      flash[:notice] = 'Deine persönlichen Daten wurden aufgenommen. ' +
                       'Bitte ergänze nun noch die Angaben für die Anmeldung.'
      redirect_to new_group_event_participation_path(group, event)
    else
      render 'register'
    end
  end

  private

  def assert_external_application_possible
    if event.external_applications?
      if event.application_possible?
        if current_user
          redirect_to show_event_path
        end
      else
        flash[:alert] = 'Das Anmeldefenster für diesen Anlass ist geschlossen.'
        application_not_possible
      end
    else
      application_not_possible
    end
  end

  def application_not_possible
    if current_user
      redirect_to show_event_path
    else
      redirect_to new_person_session_path
    end
  end

  def assert_honeypot_is_empty
    if params[:person].delete(:name).present?
      application_not_possible
    end
  end

  def create_person
    person.attributes = params[:person]
    person.save
  end

  def person
    @person ||= Person.new
  end

  alias entry person
  alias resource person

  def event
    @event ||= group.events.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def show_event_path
    group_event_path(group, event)
  end

  def devise_controller?
    true  # hence, no login required
  end


end
