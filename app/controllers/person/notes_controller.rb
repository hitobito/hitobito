# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Person::NotesController < ApplicationController

  class_attribute :permitted_attrs

  authorize_resource except: :index

  decorates :group, :person

  respond_to :html

  self.permitted_attrs = [:text]

  def index
    @group = Group.find(params[:id])
    authorize!(:index_person_notes, @group)

    @notes = Person::Note
             .includes(:author, person: :groups)
             .where(person: Person.in_layer(@group))
             .where(person: Person.in_or_below(@group))
             .page(params[:notes_page])
             .per(100)

    respond_with(@notes)
  end

  def create
    @group = Group.find(params[:group_id])
    @person = Person.find(params[:person_id])
    @note = @person.notes.create(permitted_params.merge(author_id: current_user.id))

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # create.js.haml
    end
  end

  def destroy
    @group = Group.find(params[:group_id])
    @person = Person.find(params[:person_id])
    @note = Person::Note.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # destroy.js.haml
    end
  end

  private

  def permitted_params
    params.require(:person_note).permit(permitted_attrs)
  end

end
