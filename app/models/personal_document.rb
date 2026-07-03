# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: personal_documents
#
#  id          :bigint           not null, primary key
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  author_id   :bigint           not null
#  label_id    :bigint
#  person_id   :bigint           not null
#
# Indexes
#
#  index_personal_documents_on_author_id  (author_id)
#  index_personal_documents_on_label_id   (label_id)
#  index_personal_documents_on_person_id  (person_id)
#
class PersonalDocument < ApplicationRecord
  has_paper_trail meta: {main_id: ->(r) { r.person_id },
                         main_type: Person.sti_name}

  belongs_to :person
  belongs_to :label, class_name: "PersonalDocumentLabel"
  belongs_to :author, class_name: "Person"
  validates_by_schema

  has_one_attached :file
  validates :file, presence: true

  def to_s(format = :default)
    case format
    when :long
      "#{label} (#{filename})"
    else
      label&.to_s
    end
  end

  def filename
    file&.filename.to_s
  end
end
