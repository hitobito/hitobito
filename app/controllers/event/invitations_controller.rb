# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::InvitationsController < CrudController
  #todo-later: include AsyncDownload

  self.permitted_attrs = [:event_id, :person_id, :participation_type]

  self.nesting = [Group, Event]

  # TODO: open / accepted is not distinguished yet
  self.sort_mappings = {status: ["declined_at"]}

  decorates :group, :event

  prepend_before_action :parent, :group


  ## def index: respond_to
  ## see hitobito/app/controllers/events_controller.rb
  ## + job
  ## + ..

  def create
    super(location: group_event_invitations_path(@group, @event))
  end

  def index
    respond_to do |format|
      format.html { super }
      #todo-later: format.csv  { render_tabular_in_background(:csv) }
      format.csv  { render_tabular(:csv) }
    end
  end

  private

  def group
    @group = Group.find(params[:group_id])
  end

  def event
    @event = group.events.find(params[:event_id])
  end

  def set_success_notice
    if action_name.to_s == "create"
      msg = I18n.t("event_invitations.create.flash.success",
        recipient_name: entry.person.full_name,
        participation_type: entry.participation_type.constantize.model_name.human)
    elsif action_name.to_s == "destroy"
      msg = I18n.t("event_invitations.destroy.flash.success",
        recipient_name: entry.person.full_name)
    end

    flash[:notice] = msg
  end

  def authorize_class
    authorize!(:index_invitations, event)
  end

  # todo-later: This seems not to work yet...
  #def render_tabular_in_background(format, name = :invitation_export)
  #  with_async_download_cookie(format, name) do |filename|
  #    Export::InvitationsExportJob.new(format,
  #                                current_person.id,
  #                                group.id,
  #                                filename: filename).enqueue!
  #  end
  #end

  def render_tabular(format)
    exporter = Export::Tabular::Invitations::List
    send_data exporter.export(format, entries, ability), type: format
  end

  def ability
    @ability ||= Ability.new(Person.find(current_user.id))
  end

  class << self
    def model_class
      Event::Invitation
    end
  end
end
