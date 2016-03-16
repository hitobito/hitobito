# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Person::NotesController < CrudController

  self.nesting = Group, Person

  self.permitted_attrs = [:text]

  decorates :group, :person

  # load group before authorization
  prepend_before_action :parent

  def create
    super(location: group_person_path(@group, @person))
  end

  private

  def build_entry
    person.notes.new(author_id: current_user.id)
  end

  def person
    parent
  end

  # model_params may be empty
  def permitted_params
    model_params.present? ? model_params.permit(permitted_attrs) : {}
  end

  def return_path
    if params[:return_url].present?
      begin
        uri = URI.parse(params[:return_url])
        uri.path + (uri.fragment ? "\##{uri.fragment}" : '')
      rescue URI::Error
        nil
      end
    end
  end

  class << self
    def model_class
      Person::Note
    end
  end

end
