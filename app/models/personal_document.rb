# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocument < ApplicationRecord
  belongs_to :person, optional: false
  belongs_to :personal_document_label
  belongs_to :author, class_name: "Person", optional: false

  has_one_attached :file
  validates :file, presence: true

  def to_s
    personal_document_label&.to_s
  end

  def filename
    file&.filename.to_s
  end

end
