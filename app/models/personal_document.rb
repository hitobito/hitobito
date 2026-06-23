# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocument < ApplicationRecord
  belongs_to :person
  belongs_to :label, class_name: PersonalDocumentLabel.sti_name
  belongs_to :author, class_name: "Person"
  validates_by_schema

  has_one_attached :file
  validates :file, presence: true

  def to_s
    label&.to_s
  end

  def filename
    file&.filename.to_s
  end
end
