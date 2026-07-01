# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: personal_document_labels
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class PersonalDocumentLabel < ApplicationRecord
  has_many :personal_documents, dependent: :restrict_with_error

  def to_s
    name
  end
end
