# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocumentLabel < ApplicationRecord
  has_many :personal_documents, dependent: :restrict_with_error

  def to_s
    name
  end
end
