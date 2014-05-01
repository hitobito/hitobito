# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterController < ApplicationController

  helper_method :resource, :entry, :group, :event

  before_action :assert_external_application_possible
  before_action :assert_honeypot_is_empty, only: [:check, :register]

  def index
    session[:person_return_to] = show_event_path
    flash.now[:notice] = translate(:not_logged_in, event: event)
  end

  def check
    email = params[:person][:email].to_s
    if email.present?
      check_email(email)
    else
      flash.now[:alert] = translate(:email_missing)
      render 'index'
    end
  end

  def register
    if create_person
      sign_in(:person, person)
      flash[:notice] = translate(:registered)
      redirect_to new_group_event_participation_path(group, event)
    else
      render 'register'
    end
  end

  private

  def check_email(email)
    user = Person.find_by_email(email)
    if user
      send_login_and_render_index(user)
    else
      register_new_person(email)
    end
  end

  def send_login_and_render_index(user)
    Event::SendRegisterLoginJob.new(user, group, event).enqueue!
    flash.now[:notice] = translate(:person_found) + "\n\n" + translate(:email_sent)
    render 'index'
  end

  def register_new_person(email)
    @person = Person.new(email: email)
    flash.now[:notice] = translate(:form_data_missing)
    render 'register'
  end

  def assert_external_application_possible
    if event.external_applications?
      if event.application_possible?
        redirect_to show_event_path if current_user
      else
        flash[:alert] = translate(:application_window_closed)
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
    person.attributes = params.require(:person).permit(PeopleController.permitted_attrs)
    person.save
  end

  def person
    @person ||= Person.new
  end

  alias_method :entry, :person
  alias_method :resource, :person

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
