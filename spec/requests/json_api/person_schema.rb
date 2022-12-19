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
            attributes: {
              type: :object,
              properties: {
                first_name: { type: :string },
                last_name: { type: :string }
              },
              description: 'Person attributes'
            },
            relationships: relationships
          }
        }
      }
    }
  end

  def relationships
    { type: :object,
      attributes: {
        phone_numbers: {
          type: :object,
          attributes: 
          data: [{
            type: 'phone_numbers',
            id: { type: :string },
            method: 'update'
          }]
        }
      }
    }
  end
end
