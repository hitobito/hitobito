# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventParticipationsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:event, :controller_params]

  def initialize(format, user_id, event, controller_params)
    super()
    @format = format
    @user_id = user_id
    @tempfile_name = 'event-participations-export'
    @event = event
    @controller_params = controller_params
    @exporter = exporter
  end

  private

  def send_mail(recipient, file, format)
    Export::EventParticipationsExportMailer.completed(recipient, file, format).deliver_now
  end

  def entries
    @entries ||= Event::ParticipationFilter.new(@event,
                                                current_user,
                                                @controller_params).list_entries
  end

  def exporter
    if @controller_params[:details] && Ability.new(current_user).can?(:show_details, entries.first)
      Export::Tabular::People::ParticipationsFull
    else
      Export::Tabular::People::ParticipationsAddress
    end
  end

  def current_user
    @current_user ||= Person.find(@user_id)
  end
end
