class PersonalDocument < ApplicationRecord
  belongs_to :person, optional: false
  belongs_to :personal_document_label
  belongs_to :author, class_name: "Person", optional: false

  has_one_attached :file
  validates :file, presence: true

  def to_s
    personal_document_label&.to_s
  end

end
