# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class JsonApi::PersonSchema

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
            type: { type: :string, enum: ['people'], default: 'people'},
            attributes: attributes,
            relationships: relationships
          }
        },
        included: included
      }
    }
  end

  def attributes
    { type: :object,
      properties: {
        first_name: { type: :string },
        last_name: { type: :string }
      },
      description: 'Person attributes' }
  end

  def relationships
    { type: :object,
      properties: {
        phone_numbers: {
          type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  type: { type: :string, enum: [:phone_numbers], default: :phone_numbers },
                  id: { type: :string },
                  method: { type: :string, enum: [:update], default: :update },
                }
              }
            }
          }
        }
      }
    }
  end

  def included
    { type: :array,
      items: {
        type: :object,
        properties: {
          type: { type: :string, enum: [:phone_numbers], default: :phone_numbers },
          id: { type: :string },
          attributes: {
            type: :object,
            properties: {
              number: { type: :string }
            }
          }
        }
      }
    }
  end
end
