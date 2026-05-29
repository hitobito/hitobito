# frozen_string_literal: true

class PersonalDocumentsController < CrudController
  self.nesting = Group, Person
  self.permitted_attrs = [:file, :personal_document_label_id, :person_id]

  before_save :set_person_and_author

  # prepend_before_action :parent


  private

  def build_entry
    parent.personal_documents.build
  end

  def set_person_and_author
    entry.author = current_person
  end

end
