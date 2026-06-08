# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participations::SendMailsController < ApplicationController
  def create
    authorize!(:send_mails, participation)
    raise "Invalid mail type" unless mail_type_valid?

    dispatch_mail
    redirect_to_success
  end

  private

  def dispatch_mail = send(:"dispatch_#{mail_type}_mail")

  def dispatch_event_application_confirmation_mail
    LocaleSetter.with_locale(person: participation.person) do
      Event::ParticipationMailer.confirmation(participation).deliver_later
    end
  end

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= Event.find(params[:event_id])

  def participation
    @participation ||= Event::Participation.find(params[:participation_id])
  end

  def mail_type
    @mail_type ||= params[:mail_type]
  end

  def mail_type_valid?
    participation.manually_sendable_mails.include?(mail_type)
  end

  def redirect_to_success
    redirect_to group_event_participation_path(group, event, participation),
      flash: {notice: t(".success")}
  end
end
