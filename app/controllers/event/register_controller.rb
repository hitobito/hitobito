# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RegisterController < ApplicationController
  include PrivacyPolicyAcceptable
  include Events::RegistrationClosedInfo

  helper_method :resource, :entry, :group, :event, :manager, :self_service_managed_enabled?

  before_action :assert_external_application_possible
  before_action :assert_honeypot_is_empty, only: [:check, :register]

  def index
    session[:person_return_to] = show_event_path
    flash.now[:notice] = translate(:not_logged_in, event: event)
  end

  def check # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    email = params[:person][:email].to_s
    if Truemail.valid?(email)
      # check_mail
      if (user = Person.find_by(email: email))
        # send_login_and_render_index
        Event::SendRegisterLoginJob.new(user, group, event).enqueue!
        email_sent_key = FeatureGate.enabled?("people.people_managers") ? :email_sent_manager : :email_sent # rubocop:disable Layout/LineLength
        flash.now[:notice] = translate(:person_found) + "\n\n" + translate(email_sent_key)
        render "index"
      else
        # register_new_person
        @person = Person.new(email: email)
        flash.now[:notice] = translate(:form_data_missing)
        render "register", status: :unprocessable_content
      end
    else
      flash.now[:alert] = translate(:email_invalid)
      render "index", status: :unprocessable_content
    end
  end

  def register
    if save_entry
      set_privacy_policy_acceptance if privacy_policy_needed_and_accepted?

      sign_in(:person, entry.person)
      flash[:notice] = registered_notice
      redirect_to return_path || new_group_event_participation_path(group, event)
    else
      add_privacy_policy_not_accepted_error(entry)
      render "register", status: :unprocessable_content
    end
  end

  private

  # NOTE: Wagon Hook - insieme
  def save_entry
    entry.valid? && privacy_policy_accepted? && entry.save
  end

  def registered_notice
    if manager
      return translate(:registered_manager)
    end

    translate(:registered)
  end

  def assert_external_application_possible
    if event.external_applications?
      if event.application_possible?
        redirect_to show_event_path if current_user
      else
        flash[:alert] = registration_closed_info
        redirect_to event_or_login_page
      end
    else
      redirect_to event_or_login_page
    end
  end

  def assert_honeypot_is_empty
    if params[params_key].delete(:verification).present?
      redirect_to event_or_login_page
    end
  end

  def person
    @person ||= Person.new
  end

  def entry
    @participation_contact_data ||= contact_data_class.new(event, person, model_params)
  end

  def manager
    @manager ||= true?(params[:manager]) && self_service_managed_enabled?
  end

  def contact_data_class
    if manager
      Event::ParticipationContactDatas::Manager
    else
      Event::ParticipationContactData
    end
  end

  def model_params
    params_key ? params.require(params_key).permit(PeopleController.permitted_attrs) : {}
  end

  def params_key
    [contact_data_class.to_s.underscore.tr("/", "_"),
      "person"].find { |key| params.key?(key) }
  end

  alias_method :resource, :person # used by devise-form

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

  def privacy_policy_param
    params.require(params_key)[:privacy_policy_accepted]
  end

  def return_path
    if params[:return_url].present?
      begin
        URI.parse(params[:return_url]).path
      rescue URI::Error
        nil
      end
    end
  end

  def self_service_managed_enabled?
    FeatureGate.enabled?("people.people_managers") &&
      FeatureGate.enabled?("people.people_managers.self_service_managed_creation")
  end
end
