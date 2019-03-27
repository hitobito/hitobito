#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
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

  def check # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    email = params[:person][:email].to_s
    if email.present?
      # check_mail
      if (user = Person.find_by(email: email))
        # send_login_and_render_index
        Event::SendRegisterLoginJob.new(user, group, event).enqueue!
        flash.now[:notice] = translate(:person_found) + "\n\n" + translate(:email_sent)
        render 'index'
      else
        # register_new_person
        @person = Person.new(email: email)
        flash.now[:notice] = translate(:form_data_missing)
        render 'register'
      end
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

  def assert_external_application_possible
    if event.external_applications?
      if event.application_possible?
        redirect_to show_event_path if current_user
      else
        flash[:alert] = translate(:application_window_closed)
        redirect_to event_or_login_page
      end
    else
      redirect_to event_or_login_page
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

  alias entry person
  alias resource person

  def event
    @event ||= group.events.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def event_or_login_page
    if current_user
      show_event_path
    else
      new_person_session_path
    end
  end

  def show_event_path
    group_event_path(group, event)
  end

  def devise_controller?
    true # hence, no login required
  end


end
