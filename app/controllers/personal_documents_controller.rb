# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocumentsController < CrudController
  self.nesting = Group, Person
  self.permitted_attrs = [:file, :personal_document_label_id, :person_id, :description]

  before_save :set_person_and_author

  private

  def build_entry
    parent.personal_documents.build
  end

  def set_person_and_author
    entry.author = current_person
  end

end
