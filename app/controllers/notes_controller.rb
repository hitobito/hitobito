# frozen_string_literal: true

#  Copyright (c) 2012-2021, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NotesController < ApplicationController

  decorates :group, :person

  def index
    authorize!(:index_notes, group)
    @notes = entries
  end

  def create
    @note = subject.notes.build(permitted_params.merge(author_id: current_user.id))
    authorize!(:create, @note)
    @note.save

    respond_to do |format|
      format.html { redirect_to subject_path }
      format.js { group } # create.js.haml
    end
  end

  def destroy
    authorize!(:destroy, note)
    note.destroy

    respond_to do |format|
      format.html { redirect_to subject_path }
      format.js # destroy.js.haml
    end
  end

  private

  def entries
    Note
      .preload(:subject, :author)
      .below_in_layer(group)
      .list
      .page(params[:notes_page])
      .tap do |notes|
      Person::PreloadGroups.for(notes.collect(&:subject).select { |s| s.is_a?(Person) })
      Person::PreloadGroups.for(notes.collect(&:author))
    end
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def note
    @note ||= subject.notes.find(params[:id])
  end

  def subject
    if params[:person_id]
      person
    else
      group
    end
  end

  def permitted_params
    params.require(:note).permit(:text)
  end

  def subject_path
    case note.subject
    when Group then group_path(id: group.id)
    when Person then person_path(id: person.id)
    end
  end

end
