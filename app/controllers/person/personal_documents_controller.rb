# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class Person::PersonalDocumentsController < SimpleCrudController
  self.nesting = Group, Person
  self.permitted_attrs = [:file, :label_id, :description]

  before_create :set_author

  def authorize_class
    authorize!(:index, PersonalDocument.new(person: parent))
  end

  private

  def set_author
    entry.author ||= current_person
  end
end
