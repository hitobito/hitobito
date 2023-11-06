# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class JsonApi::GroupSchema

  def self.read
    self.new.data
  end

  def data
    { type: :object,
      properties: {
        data: {
          type: :object,
          properties: {
            id: { type: :string, description: 'ID'},
            type: { type: :string, enum: ['groups'], default: 'groups'},
          }
        },
      }
    }
  end

  def attributes
    { type: :object,
      properties: {
        name: { type: :string },
        description: { type: :string }
      },
      description: 'Group attributes' }
  end
end
