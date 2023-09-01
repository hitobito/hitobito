# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PublicEventsController < ApplicationController
  # show event-tags if they are provided
  include DryCrud::RenderCallbacks
  define_render_callbacks :show
  include Tags

  # handle authorization
  skip_authorization_check
  skip_before_action :authenticate_person!
  before_action :assert_public_access, :assert_external_application_possible

  helper_method :entry, # behave like most hitobito-controllers
                :resource, # enable login-form
                :group, :event, # enable external login
                :can? # enable permission checks

  decorates :entry
  delegate :can?, to: :ability

  # Allow wagons to hide application attrs
  class_attribute :render_application_attrs
  helper_method :render_application_attrs?

  self.render_application_attrs = true

  private

  def render_application_attrs?
    render_application_attrs && entry.participant_types.present?
  end

  def assert_external_application_possible
    session[:person_return_to] = event_url
    redirect_to new_person_session_path unless entry.external_applications
  end

  def assert_public_access
    redirect_to event_url if current_user
  end

  def event_url
    group_event_path(group, entry)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def entry
    @entry ||= group.events.find(params[:id])
  end

  def person
    @person ||= Person.new
  end

  def ability
    Ability.new(current_person)
  end

  alias resource person # used by devise-form
  alias event entry # used by check-email-form
end
