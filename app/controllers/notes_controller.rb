# encoding: utf-8

#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class NotesController < ApplicationController

  class_attribute :permitted_attrs
  self.permitted_attrs = [:text]

  authorize_resource except: :index

  decorates :group, :person

  respond_to :html


  def index
    authorize!(:index_notes, group)

    @notes = Note
             .includes(:author, subject: :groups)
             .where(subject: Person.in_layer(group))
             .where(subject: Person.in_or_below(group))
             .list
             .page(params[:notes_page])
             .per(100)

    respond_with(@notes)
  end

  def create
    group
    @person = Person.find(params[:person_id])
    @note = @person.notes.create(permitted_params.merge(author_id: current_user.id))

    respond_to do |format|
      format.js # create.js.haml
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.js # destroy.js.haml
    end
  end

  private

  def group
    @group ||= Group.find(params[:group_id])
  end

  def permitted_params
    params.require(:note).permit(permitted_attrs)
  end

end
