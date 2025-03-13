# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participations::MailDispatchesController < ApplicationController
  def create
    authorize!(:create, event)
    raise "Invalid mail type" unless mail_type_valid?

    send(:"send_#{mail_type}_mail")
    redirect_to_success
  end

  private

  def send_event_application_confirmation_mail = Event::ParticipationMailer.confirmation(participation).deliver_later

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= Event.find(params[:event_id])

  def participation = @participation ||= Event::Participation.find(params[:participation_id])

  def mail_type = @mail_type ||= params[:mail_type]

  def mail_type_valid? = Event::Participation::MANUALLY_SENDABLE_PARTICIPANT_MAILS.include?(mail_type)

  def redirect_to_success = redirect_to group_event_participation_path(group, event, participation), flash: {notice: t(".success")}
end
