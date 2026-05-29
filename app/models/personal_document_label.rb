class PersonalDocumentLabel < ApplicationRecord
  has_many :personal_documents, dependent: :restrict_with_error

  def to_s
    name
  end
end
